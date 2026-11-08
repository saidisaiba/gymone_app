import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyCachedSteps = 'cached_steps';
  static const String _keyCachedWater = 'cached_water';
  static const String _keyCachedProfilePic = 'cached_profile_pic';
  static const String _keyCachedUser = 'cached_user';

  static Future<void> saveHealthMetricsLocal(int steps, int water) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCachedSteps, steps);
    await prefs.setInt(_keyCachedWater, water);
  }

  static Future<Map<String, int>> getCachedHealthMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'steps': prefs.getInt(_keyCachedSteps) ?? 7500,
      'water': prefs.getInt(_keyCachedWater) ?? 6,
    };
  }

  static Future<void> saveProfilePicture(String urlOrPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedProfilePic, urlOrPath);
  }

  static Future<String?> getCachedProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedProfilePic);
  }

  static Future<void> cacheUserSession(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedUser, jsonEncode(userJson));
  }

  static Future<Map<String, dynamic>?> getCachedUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyCachedUser);
    if (str != null) return jsonDecode(str);
    return null;
  }
}
