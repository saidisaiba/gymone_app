import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/step_tracker.dart';
import '../services/sync_service.dart';
import 'admin_dashboard_screen.dart';
import 'client_dashboard_screen.dart';
import 'coach_dashboard_screen.dart';

/// Routes to the right dashboard for the account's role and starts the on-device
/// services (step counting + background sync) for the signed-in account.
class DashboardScreen extends StatefulWidget {
  final UserModel user;
  final bool startedOffline;

  const DashboardScreen({super.key, required this.user, this.startedOffline = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServices();
  }

  Future<void> _startServices() async {
    final id = widget.user.id;
    if (!widget.startedOffline) await SyncService.restoreFromServer(id);
    await StepTracker.instance.start(id);
    await SyncService.syncPending(id);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final id = widget.user.id;
    if (state == AppLifecycleState.resumed) {
      StepTracker.instance.reloadToday();
      SyncService.syncPending(id);
    } else if (state == AppLifecycleState.paused) {
      SyncService.scheduleSync(id, delay: const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (user.isAdmin) return AdminDashboardScreen(user: user);
    if (user.isCoach) return CoachDashboardScreen(user: user);
    return ClientDashboardScreen(user: user, startedOffline: widget.startedOffline);
  }
}
