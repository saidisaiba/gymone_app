import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const GymoneApp());
}

class GymoneApp extends StatelessWidget {
  const GymoneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrossFit 1000 Hills',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C1611),
        primaryColor: const Color(0xFF84CC16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF84CC16),
          secondary: Color(0xFF84CC16),
          surface: Color(0xFF14221A),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
