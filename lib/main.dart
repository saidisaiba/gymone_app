import 'package:flutter/material.dart';

import 'app_session.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'widgets/app_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrossFitApp());
}

class CrossFitApp extends StatefulWidget {
  const CrossFitApp({super.key, this.home});

  /// Overrides the first screen (used by tests).
  final Widget? home;

  @override
  State<CrossFitApp> createState() => _CrossFitAppState();
}

class _CrossFitAppState extends State<CrossFitApp> {
  @override
  void initState() {
    super.initState();
    ApiService.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    ApiService.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    signOut(reason: ApiService.lastError.isNotEmpty ? ApiService.lastError : 'Your session has expired. Please sign in again.');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrossFit 1000 Hills',
      navigatorKey: navigatorKey,
      theme: buildAppTheme(),
      home: widget.home ?? const StartupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Restores the previous session: online → refresh the profile from the server;
/// offline → open the cached profile so classes, WOD and activity are still usable.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return _toLogin();

    final user = await ApiService.me();
    if (user != null) return openDashboard(user);

    if (ApiService.lastFailureWasNetwork) {
      final cached = await StorageService.getCachedUserSession();
      if (cached != null) return openDashboard(UserModel.fromJson(cached), offline: true);
    }
    _toLogin();
  }

  void _toLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 96),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.lime),
          ],
        ),
      ),
    );
  }
}
