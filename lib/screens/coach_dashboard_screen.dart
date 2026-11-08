import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/app_logo.dart';
import 'schedule_screen.dart';
import 'user_list_screen.dart';
import 'login_screen.dart';

class CoachDashboardScreen extends StatelessWidget {
  final UserModel user;
  const CoachDashboardScreen({super.key, required this.user});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1611),
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Text('Coach - ${user.name}', style: const TextStyle(color: Color(0xFF84CC16), fontSize: 16)),
          ],
        ),
        backgroundColor: const Color(0xFF14221A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF84CC16)),
            tooltip: 'Log Off',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coach Management Portal', style: TextStyle(color: Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14221A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFF84CC16)),
                title: const Text('Assigned Class Schedule & Workouts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View and manage classes assigned to you', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(userId: user.id.toString()))),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14221A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF84CC16)),
                title: const Text('View Clients / Athletes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Inspect member profiles and subscription statuses', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
