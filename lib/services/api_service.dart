import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'local_db.dart';
import 'storage_service.dart';

/// Client for https://crossfit1000hills.com/calendar/api.php
///
/// * `login` returns a signed token; it is stored on the device and sent as
///   `Authorization: Bearer <token>` on every other request. The server identifies the
///   member from the token.
/// * A 401 response means the session expired or the password changed: the token is
///   cleared and the user must sign in again.
/// * Server versions have used different action names (e.g. `get_classes` vs
///   `schedule`). Each call lists the names to try; the next one is only tried when the
///   server answers "Unknown API action".
/// * List calls are cached on the device so the app keeps working offline.
class ApiService {
  static const String baseUrl = 'https://crossfit1000hills.com/calendar/api.php';
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Last error message from the server, for showing to the user.
  static String lastError = '';

  /// True when the last failure was "no connection" rather than a server refusal.
  static bool lastFailureWasNetwork = false;

  /// True when the last list was served from the offline cache.
  static bool lastResultFromCache = false;

  /// Notified when the server rejects the session, so the UI can return to sign-in.
  static final ValueNotifier<int> sessionExpired = ValueNotifier(0);

  @visibleForTesting
  static http.Client client = http.Client();

  static final _unknownAction = RegExp(r'(unknown|invalid) api action', caseSensitive: false);

  // ------------------------------------------------------------------ helpers

  static Uri _uri(String action, [Map<String, String>? params]) =>
      Uri.parse(baseUrl).replace(queryParameters: {'action': action, ...?params});

  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<_Reply> _send(String method, String action, Map<String, String>? query, Map<String, dynamic>? body) async {
    try {
      final headers = await _headers();
      final response = method == 'GET'
          ? await client.get(_uri(action, query), headers: headers).timeout(timeoutDuration)
          : await client.post(_uri(action, query), headers: headers, body: jsonEncode(body ?? {})).timeout(timeoutDuration);
      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } on FormatException {
        data = null;
      }
      return _Reply(response.statusCode, data);
    } on TimeoutException {
      return const _Reply.network();
    } on http.ClientException {
      return const _Reply.network();
    } catch (e) {
      // SocketException / HandshakeException etc. (dart:io types aren't available on web).
      return const _Reply.network();
    }
  }

  /// Tries each action name in turn; returns the decoded body on success, otherwise null
  /// with [lastError] set.
  static Future<Map<String, dynamic>?> _call(String method, List<String> actions,
      {Map<String, String>? query, Map<String, dynamic>? body}) async {
    late _Reply reply;
    for (final action in actions) {
      reply = await _send(method, action, query, body);
      final unknown = reply.status == 404 && _unknownAction.hasMatch(reply.message);
      if (!unknown) break;
    }

    lastFailureWasNetwork = reply.network;
    if (reply.network) {
      lastError = 'Unable to reach the server. Check your internet connection.';
      return null;
    }
    if (reply.status == 401 && actions.first != 'login') {
      await StorageService.clearSession();
      sessionExpired.value++;
    }
    final data = reply.data;
    if (reply.status < 200 || reply.status >= 300 || data == null || data['status'] != 'success') {
      lastError = reply.message.isNotEmpty ? reply.message : 'Request failed (${reply.status}). Please try again.';
      return null;
    }
    lastError = '';
    return data;
  }

  /// GET a list. Fresh data is cached; when offline the cached copy is returned.
  static Future<List<dynamic>> _list(List<String> actions, String key, {Map<String, String>? query, String? cacheKey}) async {
    lastResultFromCache = false;
    final data = await _call('GET', actions, query: query);
    final ck = cacheKey ?? actions.first;
    if (data != null) {
      final list = data[key] is List ? data[key] as List<dynamic> : <dynamic>[];
      try {
        await LocalDb.putCache(ck, list);
      } catch (_) {/* cache is best-effort */}
      return list;
    }
    if (lastFailureWasNetwork) {
      try {
        final cached = await LocalDb.getCache(ck);
        if (cached?.value is List) {
          lastResultFromCache = true;
          return cached!.value as List<dynamic>;
        }
      } catch (_) {}
    }
    return [];
  }

  /// The server stores members with role `user` in some versions and `client` in
  /// others; send back whichever the server uses.
  static String serverRoleFor(String role, {String? existingServerRole}) {
    if (role != 'client') return role;
    if (existingServerRole != null && UserModel.memberRoleNames.contains(existingServerRole)) return existingServerRole;
    return _memberRoleName;
  }

  /// The live database stores members as `user` (users.role is ENUM('user','coach','admin')).
  static String _memberRoleName = 'user';

  // ------------------------------------------------------------ authentication

  /// Signs in. Requires a network connection: there is no offline sign-in,
  /// because a cached profile can't prove the password is correct.
  static Future<UserModel?> login(String email, String password) async {
    final data = await _call('POST', ['login'], body: {'email': email.trim().toLowerCase(), 'password': password});
    if (data == null) return null;
    if (data['token'] is! String || data['user'] is! Map) {
      lastError = 'The server did not return a session. Please contact the gym.';
      return null;
    }
    final userJson = Map<String, dynamic>.from(data['user']);
    await StorageService.saveToken(data['token'] as String);
    await StorageService.cacheUserSession(userJson);
    return UserModel.fromJson(userJson);
  }

  static Future<void> logout() async {
    await StorageService.clearSession();
    try {
      await LocalDb.clearCache();
    } catch (_) {}
  }

  /// The signed-in user's fresh profile (null if signed out / expired / offline).
  static Future<UserModel?> me() async {
    final data = await _call('GET', ['me', 'profile']);
    if (data?['user'] is! Map) return null;
    final json = Map<String, dynamic>.from(data!['user']);
    if (data['subscription'] is Map && json['subscription'] == null) json['subscription'] = data['subscription'];
    await StorageService.cacheUserSession(json);
    return UserModel.fromJson(json);
  }

  // ------------------------------------------------------------------ payments

  /// Member: submits a MoMo payment for the gym to confirm (status stays pending).
  /// Admin: pass the member's [userId] to record a verified payment immediately.
  static Future<Map<String, dynamic>?> pay({required String userId, required String phone, String? reference}) {
    return _call('POST', ['pay'], body: {
      'user_id': userId, // ignored by the server unless the caller is an admin
      'phone': phone,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
    });
  }

  /// Admin: payments waiting for confirmation.
  static Future<List<dynamic>> getPaymentRequests() async => (await _call('GET', ['payment_requests']))?['requests'] as List<dynamic>? ?? [];

  static Future<bool> approvePayment(int requestId) async => await _call('POST', ['approve_payment'], body: {'request_id': requestId}) != null;

  static Future<bool> rejectPayment(int requestId, {String note = ''}) async =>
      await _call('POST', ['reject_payment'], body: {'request_id': requestId, 'note': note}) != null;

  /// Admin: set a member's plan and expiry date directly.
  static Future<bool> updateSubscription({required int userId, required String expiryDate, String membershipType = 'Monthly', double amount = 0}) async =>
      await _call('POST', ['update_subscription'], body: {
        'user_id': userId,
        'expiry_date': expiryDate,
        'membership_type': membershipType,
        'amount': amount,
        'payment_method': 'MoMo',
      }) !=
      null;

  // --------------------------------------------------------------- admin users

  static Future<List<UserModel>> getUsers() async {
    final list = await _list(['get_users'], 'users');
    final users = list.whereType<Map>().map((u) => UserModel.fromJson(Map<String, dynamic>.from(u))).toList();
    final memberRole = users.map((u) => u.serverRole).firstWhere(UserModel.memberRoleNames.contains, orElse: () => '');
    if (memberRole.isNotEmpty) _memberRoleName = memberRole;
    return users;
  }

  static Future<UserModel?> getUser(String userId) async {
    final data = await _call('GET', ['get_user'], query: {'id': userId, 'user_id': userId});
    if (data?['user'] is Map) return UserModel.fromJson(Map<String, dynamic>.from(data!['user']));
    if (lastFailureWasNetwork) return null;
    // Older servers have no get_user: fall back to the full list.
    final users = await getUsers();
    for (final u in users) {
      if (u.id.toString() == userId) return u;
    }
    return null;
  }

  static Future<bool> addUser(Map<String, dynamic> userData) async {
    final body = Map<String, dynamic>.from(userData);
    body['role'] = serverRoleFor(body['role']?.toString() ?? 'client');
    return await _call('POST', ['add_user', 'register'], body: body) != null;
  }

  static Future<bool> updateUser(UserModel original, Map<String, dynamic> changes) async {
    final body = {
      'id': original.id,
      'user_id': original.id,
      ...changes,
    };
    body['role'] = serverRoleFor(body['role']?.toString() ?? original.role, existingServerRole: original.serverRole);
    return await _call('POST', ['update_user'], body: body) != null;
  }

  static Future<bool> deleteUser(String userId) async =>
      await _call('POST', ['delete_user'], body: {'user_id': int.tryParse(userId) ?? userId, 'id': int.tryParse(userId) ?? userId}) != null;

  // ------------------------------------------------------------ gym content

  /// Today's WOD, or the latest announcement whose title mentions a WOD/workout.
  /// Returns null when the gym hasn't published one (never an invented workout).
  static Future<Map<String, dynamic>?> getTodayWod() async {
    lastResultFromCache = false;
    final data = await _call('GET', ['get_today_wod']);
    if (data?['wod'] is Map) {
      final wod = Map<String, dynamic>.from(data!['wod']);
      try {
        await LocalDb.putCache('wod', wod);
      } catch (_) {}
      return wod;
    }
    if (lastFailureWasNetwork) {
      try {
        final cached = await LocalDb.getCache('wod');
        if (cached?.value is Map) return Map<String, dynamic>.from(cached!.value as Map);
      } catch (_) {}
      return null;
    }
    for (final a in await getAnnouncements()) {
      if (a is Map && RegExp(r'wod|workout', caseSensitive: false).hasMatch('${a['title']}')) {
        return {'title': a['title'], 'details': a['message'] ?? a['text'] ?? ''};
      }
    }
    return null;
  }

  /// Class schedule. Coaches receive only the classes assigned to them.
  static Future<List<dynamic>> getClasses() => _list(['get_classes', 'schedule'], 'classes', cacheKey: 'classes');

  /// The signed-in member's bookings.
  static Future<List<dynamic>> getUserBookings() => _list(['get_user_bookings', 'my_bookings'], 'bookings', cacheKey: 'my_bookings');

  /// Admin: every booking. Coach: bookings for their own classes.
  static Future<List<dynamic>> getAllBookings() => _list(['get_all_bookings'], 'bookings');

  /// Books a class for the signed-in member. Returns false (see [lastError]) on failure.
  static Future<bool> bookClass(String classId) async =>
      await _call('POST', ['book_class', 'book'], body: {'class_id': int.tryParse(classId) ?? classId}) != null;

  static Future<bool> cancelBooking(int bookingId) async => await _call('POST', ['cancel_booking'], body: {'booking_id': bookingId}) != null;

  static Future<List<dynamic>> getAnnouncements() => _list(['get_announcements', 'announcements'], 'announcements', cacheKey: 'announcements');

  static Future<List<dynamic>> getBirthdays() => _list(['get_birthdays', 'upcoming_birthdays'], 'birthdays', cacheKey: 'birthdays');

  // ------------------------------------------------------------ activity sync

  /// Uploads one day's compact summary (steps + water). Detailed history stays on the device.
  static Future<bool> saveDailyActivity(DailyActivity d) async =>
      await _call('POST', ['save_health_metrics', 'health_metrics'], body: {
        'record_date': d.day,
        'steps': d.steps,
        'step_goal': d.stepGoal,
        'water_glasses': d.water,
        'water_goal': d.waterGoal,
      }) !=
      null;

  /// Daily summaries stored on the server (used to restore history on a new phone).
  static Future<List<DailyActivity>> getActivityHistory() async {
    final data = await _call('GET', ['get_health_metrics', 'health_metrics']);
    final list = data?['metrics'] is List ? data!['metrics'] as List : const [];
    int n(dynamic v, int fallback) => int.tryParse('${v ?? ''}') ?? (v is num ? v.toInt() : fallback);
    return [
      for (final m in list.whereType<Map>())
        if (DateTime.tryParse('${m['record_date']}') != null)
          DailyActivity(
            day: '${m['record_date']}'.substring(0, 10),
            steps: n(m['steps'], 0),
            stepGoal: n(m['step_goal'], 10000),
            water: n(m['water_glasses'], 0),
            waterGoal: n(m['water_goal'], 8),
          ),
    ];
  }
}

class _Reply {
  final int status;
  final Map<String, dynamic>? data;
  final bool network;

  const _Reply(this.status, this.data) : network = false;
  const _Reply.network()
      : status = 0,
        data = null,
        network = true;

  String get message => (data?['message'] ?? '').toString();
}
