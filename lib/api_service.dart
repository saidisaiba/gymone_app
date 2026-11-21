import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://crossfit1000hills.com/calendar/api.php';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', data['token'] ?? '');
      }
      return data;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=schedule'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> bookClass(int userId, int classId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'class_id': classId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
