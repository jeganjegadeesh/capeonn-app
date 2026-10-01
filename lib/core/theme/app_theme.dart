import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const primary = Color(0xFF2563EB); // Modern Royal Blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF3B82F6);
  static const primaryContainer = Color(0xFFEFF6FF);

  // Secondary & Accents
  static const secondary = Color(0xFF4F46E5); // Indigo
  static const accent = Color(0xFF0EA5E9); // Sky
  static const emerald = Color(0xFF10B981);
  static const emeraldContainer = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amberContainer = Color(0xFFFFFBEB);
  static const rose = Color(0xFFEF4444);
  static const roseContainer = Color(0xFFFEF2F2);
  static const purple = Color(0xFF8B5CF6);
  static const purpleContainer = Color(0xFFF5F3FF);

  // Neutrals & Backgrounds
  static const background = Color(0xFFF8FAFC); // Slate 50
  static const surface = Colors.white;
  static const surfaceHover = Color(0xFFF1F5F9);
  static const sidebarBg = Color(0xFF0F172A); // Slate 900
  static const sidebarHover = Color(0xFF1E293B); // Slate 800
  static const sidebarActive = Color(0xFF2563EB);

  // Text Colors
  static const textPrimary = Color(0xFF0F172A); // Slate 900
  static const textSecondary = Color(0xFF64748B); // Slate 500
  static const textMuted = Color(0xFF94A3B8); // Slate 400
  static const textOnDark = Colors.white;
  static const textOnDarkSecondary = Color(0xFF94A3B8);

  // Borders & Dividers
  static const border = Color(0xFFE2E8F0); // Slate 200
  static const borderSubtle = Color(0xFFF1F5F9);

  // Role Badge Styling Helper
  static (Color bg, Color fg) rolePillColors(String? roleSlug) {
    switch (roleSlug?.toLowerCase()) {
      case 'super_admin':
        return (const Color(0xFFEDE9FE), const Color(0xFF5B21B6)); // Violet
      case 'admin':
        return (purpleContainer, const Color(0xFF6D28D9));
      case 'hr':
        return (const Color(0xFFCCFBF1), const Color(0xFF0F766E)); // Teal
      case 'manager':
        return (primaryContainer, primaryDark);
      case 'team_lead':
        return (amberContainer, const Color(0xFFB45309));
      case 'employee':
      default:
        return (const Color(0xFFF1F5F9), const Color(0xFF334155));
    }
  }

  // Status Badge Styling Helper
  static (Color bg, Color fg) statusPillColors(bool isActive) {
    if (isActive) {
      return (emeraldContainer, const Color(0xFF047857));
    }
    return (const Color(0xFFF1F5F9), const Color(0xFF64748B));
  }
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.rose,
        brightness: Brightness.light,
      ),
      fontFamily: 'Segoe UI', // Clean cross-platform desktop & web fallback
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.rose),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}