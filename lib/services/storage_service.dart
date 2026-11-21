import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value settings on the device (session token, goals, preferences).
/// Larger local data (activity history, workout log, PRs, offline cache) is in [LocalDb].
///
/// The API token is kept in app-private SharedPreferences. For stronger protection on
/// rooted/jailbroken devices, move it to `flutter_secure_storage` (Keychain / Android
/// Keystore) — only saveToken/getToken/clearSession need to change.
class StorageService {
  static const _keyToken = 'api_token';
  static const _keyCachedUser = 'cached_user';
  static const _keyStepGoal = 'step_goal';
  static const _keyWaterGoal = 'water_goal';
  static const _keySyncActivity = 'sync_activity_to_server';
  static const _keyCounterLast = 'step_counter_last';
  static const _keyCounterOwner = 'step_counter_owner';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---------------------------------------------------------------- session

  static Future<void> saveToken(String token) async => (await _prefs).setString(_keyToken, token);

  static Future<String?> getToken() async => (await _prefs).getString(_keyToken);

  /// Signs out on this device: removes the token and the cached profile.
  static Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyCachedUser);
  }

  /// Profile shown while offline (display only — never used to sign in).
  static Future<void> cacheUserSession(Map<String, dynamic> userJson) async =>
      (await _prefs).setString(_keyCachedUser, jsonEncode(userJson));

  static Future<Map<String, dynamic>?> getCachedUserSession() async {
    final str = (await _prefs).getString(_keyCachedUser);
    if (str == null) return null;
    try {
      final decoded = jsonDecode(str);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  // ---------------------------------------------------------------- goals

  static Future<int> getStepGoal() async => (await _prefs).getInt(_keyStepGoal) ?? 10000;
  static Future<int> getWaterGoal() async => (await _prefs).getInt(_keyWaterGoal) ?? 8;

  static Future<void> saveGoals({required int stepGoal, required int waterGoal}) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyStepGoal, stepGoal);
    await prefs.setInt(_keyWaterGoal, waterGoal);
  }

  /// When false, activity stays on the phone only (nothing is uploaded).
  static Future<bool> getSyncActivity() async => (await _prefs).getBool(_keySyncActivity) ?? true;
  static Future<void> setSyncActivity(bool value) async => (await _prefs).setBool(_keySyncActivity, value);

  // ------------------------------------------------------ step sensor state

  /// Last raw pedometer reading, and which member it was counted for.
  static Future<({int? value, int? owner})> getStepCounter() async {
    final prefs = await _prefs;
    return (value: prefs.getInt(_keyCounterLast), owner: prefs.getInt(_keyCounterOwner));
  }

  static Future<void> saveStepCounter(int value, int owner) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyCounterLast, value);
    await prefs.setInt(_keyCounterOwner, owner);
  }
}
