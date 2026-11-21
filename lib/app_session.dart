import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/step_tracker.dart';
import 'services/sync_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Opens the dashboard for [user], replacing everything on the navigation stack.
void openDashboard(UserModel user, {bool offline = false}) {
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => DashboardScreen(user: user, startedOffline: offline)),
    (_) => false,
  );
}

/// Signs out on this device and returns to the sign-in screen.
Future<void> signOut({String? reason}) async {
  SyncService.cancel();
  await StepTracker.instance.stop();
  await ApiService.logout();
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginScreen(message: reason)),
    (_) => false,
  );
}
