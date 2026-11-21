import 'dart:convert';
import 'package:flutter/foundation.dart';
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

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Raw Response: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Server returned an empty response.'
        };
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        if (data['user'] != null && data['user']['id'] != null) {
          await prefs.setInt(
              'user_id', int.parse(data['user']['id'].toString()));
        }
      }
      return data;
    } catch (e) {
      return {'status': 'error', 'message': 'Network/Parsing Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClasses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=get_classes'));
      if (response.body.isEmpty)
        return {'status': 'error', 'message': 'Empty response from server.'};
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> bookClass(int userId, int classId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=book_class'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'class_id': classId}),
      );
      if (response.body.isEmpty)
        return {'status': 'error', 'message': 'Empty response from server.'};
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserBookings(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl?action=get_user_bookings&user_id=$userId'));
      if (response.body.isEmpty)
        return {'status': 'error', 'message': 'Empty response from server.'};
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getHealthMetrics(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl?action=health_metrics&user_id=$userId'));
      if (response.body.isEmpty)
        return {'status': 'error', 'message': 'Empty response from server.'};
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveHealthMetrics(
    int userId, {
    double? weight,
    double? height,
    double? bodyFat,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=health_metrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'weight': weight,
          'height': height,
          'body_fat': bodyFat,
        }),
      );
      if (response.body.isEmpty)
        return {'status': 'error', 'message': 'Empty response from server.'};
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
