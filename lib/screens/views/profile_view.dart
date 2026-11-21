import 'package:flutter/material.dart';
import '../login_screen.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Abonnement Actif'),
            subtitle: const Text('Illimité - Renouvellement le 15/10/2026'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des présences'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Action de déconnexion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
