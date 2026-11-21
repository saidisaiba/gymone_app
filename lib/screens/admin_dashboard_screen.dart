import 'package:flutter/material.dart';

import '../app_session.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import 'activity_screen.dart';
import 'attendance_screen.dart';
import 'coach_dashboard_screen.dart' show DashboardTile;
import 'payment_requests_screen.dart';
import 'schedule_screen.dart';
import 'user_list_screen.dart';
import 'wod_timer_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserModel user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const AppLogo(size: 32),
          const SizedBox(width: 10),
          Expanded(child: Text('Admin • ${user.name}', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign out', onPressed: () => signOut())],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Management console', style: TextStyle(color: AppColors.lime, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DashboardTile(Icons.person_add, 'Add member / staff', 'Create a new account', () => showAddUserDialog(context)),
          DashboardTile(Icons.people, 'Member directory', 'Search, edit, renew memberships, receipts', () => open(const UserListScreen())),
          DashboardTile(Icons.payments_outlined, 'Payment requests', 'Approve MoMo payments submitted by members', () => open(const PaymentRequestsScreen())),
          DashboardTile(Icons.fact_check_outlined, 'Attendance', 'Bookings for every class', () => open(const AttendanceScreen())),
          DashboardTile(Icons.calendar_month, 'Class schedule', 'Classes, capacity and spots booked', () => open(ScheduleScreen(user: user))),
          DashboardTile(Icons.timer_outlined, 'WOD timer', 'For Time, AMRAP, EMOM, Tabata', () => open(const WodTimerScreen())),
          DashboardTile(Icons.directions_walk, 'My activity', 'Steps, water and goals', () => open(ActivityScreen(userId: user.id))),
        ],
      ),
    );
  }
}

Future<void> showAddUserDialog(BuildContext context, {VoidCallback? onAdded}) async {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final phoneC = TextEditingController();
  final birthC = TextEditingController();
  var role = 'client';
  String? error;
  var saving = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setD) => AlertDialog(
        title: const Text('New account', style: TextStyle(color: AppColors.lime)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary password (8+ characters)')),
            const SizedBox(height: 10),
            TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
            const SizedBox(height: 10),
            TextField(
              controller: birthC,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Birthdate (optional)', suffixIcon: Icon(Icons.cake_outlined)),
              onTap: () async {
                final d = await showDatePicker(context: dialogContext, firstDate: DateTime(1930), lastDate: DateTime.now(), initialDate: DateTime(1995));
                if (d != null) birthC.text = d.toIso8601String().substring(0, 10);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: role,
              items: const [
                DropdownMenuItem(value: 'client', child: Text('Member')),
                DropdownMenuItem(value: 'coach', child: Text('Coach')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => role = v ?? 'client',
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: AppColors.danger))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    if (nameC.text.trim().isEmpty || !emailC.text.contains('@') || passC.text.length < 8) {
                      setD(() => error = 'Enter a name, a valid email and a password of at least 8 characters.');
                      return;
                    }
                    setD(() {
                      saving = true;
                      error = null;
                    });
                    final ok = await ApiService.addUser({
                      'name': nameC.text.trim(),
                      'email': emailC.text.trim().toLowerCase(),
                      'password': passC.text,
                      'phone_number': phoneC.text.trim(),
                      'birthdate': birthC.text,
                      'role': role,
                    });
                    if (!dialogContext.mounted) return;
                    if (!ok) {
                      setD(() {
                        saving = false;
                        error = ApiService.lastError;
                      });
                      return;
                    }
                    Navigator.pop(dialogContext);
                    if (context.mounted) showMessage(context, 'Account created for ${nameC.text.trim()}.');
                    onAdded?.call();
                  },
            child: Text(saving ? 'Saving…' : 'Create'),
          ),
        ],
      ),
    ),
  );
}
