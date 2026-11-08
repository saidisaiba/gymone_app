import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const CrossFitApp());
}

class CrossFitApp extends StatelessWidget {
  const CrossFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrossFit 1000 Hills',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF84CC16),
        scaffoldBackgroundColor: const Color(0xFF0C1611),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF84CC16),
          secondary: Color(0xFF84CC16),
          surface: Color(0xFF14221A),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
