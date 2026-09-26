import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2E5AAC);
  static const background = Color(0xFFF5F6FA);
  static const textDark = Color(0xFF1C1C1E);
}

class AppTheme {
  static ThemeData light = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  );
}