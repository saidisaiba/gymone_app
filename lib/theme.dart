import 'package:flutter/material.dart';

/// Brand colours used across the app.
class AppColors {
  static const lime = Color(0xFF84CC16);
  static const background = Color(0xFF09110D);
  static const surface = Color(0xFF131F18);
  static const surfaceHigh = Color(0xFF1C3125);
  static const danger = Colors.redAccent;
  static const water = Color(0xFF38BDF8);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lime,
      onPrimary: AppColors.background,
      secondary: AppColors.lime,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.lime,
      elevation: 0,
      titleTextStyle: TextStyle(color: AppColors.lime, fontSize: 17, fontWeight: FontWeight.bold),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.background,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      labelStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Standard card container used on most screens.
BoxDecoration cardDecoration({double borderOpacity = 0.3, Color? border}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: (border ?? AppColors.lime).withValues(alpha: borderOpacity)),
    );

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text, style: const TextStyle(color: Colors.white)),
    backgroundColor: error ? AppColors.danger : const Color(0xFF3F6212),
  ));
}
