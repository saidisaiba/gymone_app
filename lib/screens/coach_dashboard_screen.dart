import 'package:flutter/material.dart';

import '../app_session.dart';
import '../models/user_model.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import 'activity_screen.dart';
import 'attendance_screen.dart';
import 'schedule_screen.dart';
import 'wod_timer_screen.dart';
import 'workout_log_screen.dart';

class CoachDashboardScreen extends StatelessWidget {
  final UserModel user;
  const CoachDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const AppLogo(size: 32),
          const SizedBox(width: 10),
          Expanded(child: Text('Coach • ${user.name}', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign out', onPressed: () => signOut())],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Coach portal', style: TextStyle(color: AppColors.lime, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DashboardTile(Icons.calendar_today, 'My classes', 'Classes assigned to you, with spots booked', () => open(ScheduleScreen(user: user))),
          DashboardTile(Icons.fact_check_outlined, 'Attendance', 'Members booked into your classes', () => open(const AttendanceScreen())),
          DashboardTile(Icons.timer_outlined, 'WOD timer', 'For Time, AMRAP, EMOM, Tabata — works offline', () => open(const WodTimerScreen())),
          DashboardTile(Icons.directions_walk, 'My activity', 'Steps, water and goals', () => open(ActivityScreen(userId: user.id))),
          DashboardTile(Icons.emoji_events_outlined, 'My training log', 'Your own workouts and PRs (stored on this phone)', () => open(WorkoutLogScreen(userId: user.id))),
        ],
      ),
    );
  }
}

class DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const DashboardTile(this.icon, this.title, this.subtitle, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: cardDecoration(),
        child: ListTile(
          leading: Icon(icon, color: AppColors.lime),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.lime, size: 16),
          onTap: onTap,
        ),
      );
}
