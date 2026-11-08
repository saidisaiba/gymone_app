import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'client_dashboard_screen.dart';
import 'coach_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.role == 'admin') {
      return AdminDashboardScreen(user: user);
    } else if (user.role == 'coach') {
      return CoachDashboardScreen(user: user);
    } else {
      return ClientDashboardScreen(user: user);
    }
  }
}
