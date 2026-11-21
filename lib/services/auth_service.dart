import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // Remplace cette URL par l'URL de ton API de connexion existante
  final String baseUrl = 'https://votre-domaine.com/api';

  // Fonction de connexion
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

        // Vérifie si le backend renvoie un succès et les données utilisateur
        if (data['success'] == true && data['user'] != null) {
          // On retourne l'objet User créé à partir de la base de données
          return User.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      // Gestion des erreurs de connexion réseau
      print('Erreur de connexion : $e');
      return null;
    }
  }
}
