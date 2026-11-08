import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // Replace this URL with your existing login API URL
  final String baseUrl = 'https://votre-domaine.com/api';

  // Login function
  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'), // Point de terminaison de ton login
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if backend returns success and user data
        if (data['success'] == true && data['user'] != null) {
          // On retourne l'objet User créé à partir de la base de données
          return User.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      // Network connection error handling
      print('Connection error : $e');
      return null;
    }
  }
}
