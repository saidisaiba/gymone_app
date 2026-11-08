import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://crossfit1000hills.com/calendar/api.php';
  static const Duration timeoutDuration = Duration(seconds: 15);

  static Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['user'] != null) {
          await StorageService.cacheUserSession(data['user']);
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {
      print('API Login Exception (Trying offline cache): $e');
      final cached = await StorageService.getCachedUserSession();
      if (cached != null && (cached['email'] == email || cached['name'] == email)) {
        return UserModel.fromJson(cached);
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> pay({required String userId, required String phone}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'phone': phone}),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('API Pay Exception: $e');
    }
    return null;
  }

  static Future<List<UserModel>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_users')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['users'] != null) {
          List list = data['users'];
          return list.map((u) => UserModel.fromJson(u)).toList();
        }
      }
    } catch (e) {
      print('API Get Users Exception: $e');
    }
    return [];
  }

  static Future<UserModel?> getUser(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_user&id=$userId')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {
      print('API Get User Exception: $e');
    }
    return null;
  }

  static Future<bool> addUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=add_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status'] == 'success';
      }
    } catch (e) {
      print('API Add User Exception: $e');
    }
    return false;
  }

  static Future<bool> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status'] == 'success';
      }
    } catch (e) {
      print('API Update User Exception: $e');
    }
    return false;
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=delete_user&id=$userId')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status'] == 'success';
      }
    } catch (e) {
      print('API Delete User Exception: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getTodayWod() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_today_wod')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['wod'] != null) {
          return data['wod'];
        }
      }
    } catch (e) {
      print('API Get Today WOD Exception: $e');
    }
    return {
      'title': 'AMRAP 20 mins',
      'details': '• 5 Pull-ups\n• 10 Push-ups\n• 15 Air Squats'
    };
  }

  static Future<List<dynamic>> getClasses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_classes')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['classes'] != null) {
          return data['classes'];
        }
      }
    } catch (e) {
      print('API Get Classes Exception: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getUserBookings(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_user_bookings&user_id=$userId')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['bookings'] != null) {
          return data['bookings'];
        }
      }
    } catch (e) {
      print('API Get User Bookings Exception: $e');
    }
    return [];
  }

  static Future<bool> bookClass({required String userId, required String classId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=book_class'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'class_id': classId}),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
    } catch (e) {
      print('API Book Class Exception: $e');
    }
    return false;
  }

  static Future<List<dynamic>> getAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_announcements')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') return data['announcements'];
      }
    } catch (e) {
      print('API Get Announcements Exception: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getBirthdays() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_birthdays')).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') return data['birthdays'];
      }
    } catch (e) {
      print('API Get Birthdays Exception: $e');
    }
    return [];
  }

  static Future<bool> saveHealthMetrics({
    required String userId,
    required int steps,
    required int stepGoal,
    required int waterGlasses,
    required int waterGoal,
  }) async {
    await StorageService.saveHealthMetricsLocal(steps, waterGlasses);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=health_metrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'steps': steps,
          'step_goal': stepGoal,
          'water_glasses': waterGlasses,
          'water_goal': waterGoal,
        }),
      ).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
    } catch (e) {
      print('API Health Metrics Exception (Saved locally): $e');
      return true;
    }
    return false;
  }
}
