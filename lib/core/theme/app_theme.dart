import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool _isDark = false;
  static bool get isDark => _isDark;
  static void setDark(bool value) {
    _isDark = value;
  }

  // Primary Brand Colors (Vibrant, high-contrast, modern Royal / Electric Blue)
  static const primary = Color(0xFF2563EB); // Modern Royal Blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF3B82F6);
  static Color get primaryContainer =>
      _isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF);

  // Secondary & Accents
  static const secondary = Color(0xFF6366F1); // Modern Indigo
  static const accent = Color(0xFF0EA5E9); // Sky
  static const emerald = Color(0xFF10B981);
  static Color get emeraldContainer =>
      _isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static Color get amberContainer =>
      _isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB);
  static const rose = Color(0xFFEF4444);
  static Color get roseContainer =>
      _isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2);
  static const purple = Color(0xFF8B5CF6);
  static Color get purpleContainer =>
      _isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.35) : const Color(0xFFF5F3FF);

  // Neutrals & Backgrounds (Adaptive!)
  // Light: Crisp slate-50 / pure white
  // Dark: Deep Obsidian / Midnight slate (Linear / Vercel style)
  static Color get background => _isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
  static Color get surface => _isDark ? const Color(0xFF131C2E) : Colors.white;
  static Color get surfaceHover => _isDark ? const Color(0xFF1A263D) : const Color(0xFFF1F5F9);
  static Color get sidebarBg => _isDark ? const Color(0xFF0B0F19) : Colors.white;
  static Color get sidebarHover => _isDark ? const Color(0xFF162035) : const Color(0xFFF1F5F9);
  static const sidebarActive = Color(0xFF2563EB);

  // Text Colors (Adaptive!)
  static Color get textPrimary => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get textMuted => _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static const textOnDark = Colors.white;
  static const textOnDarkSecondary = Color(0xFF94A3B8);

  // Borders & Dividers (Adaptive!)
  static Color get border => _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  static Color get borderSubtle => _isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9);

  // Subtle luxury card shadows
  static List<BoxShadow> get cardShadow => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ];

  // Role Badge Styling Helper (Adaptive!)
  static (Color bg, Color fg) rolePillColors(String? roleSlug) {
    if (_isDark) {
      switch (roleSlug?.toLowerCase()) {
        case 'super_admin':
          return (const Color(0xFF2E1065), const Color(0xFFC4B5FD)); // Violet
        case 'admin':
          return (const Color(0xFF3B0764), const Color(0xFFD8B4FE));
        case 'hr':
          return (const Color(0xFF042F2E), const Color(0xFF5EEAD4)); // Teal
        case 'manager':
          return (const Color(0xFF172554), const Color(0xFF93C5FD));
        case 'team_lead':
          return (const Color(0xFF451A03), const Color(0xFFFDE68A));
        case 'employee':
        default:
          return (const Color(0xFF1E293B), const Color(0xFFCBD5E1));
      }
    } else {
      switch (roleSlug?.toLowerCase()) {
        case 'super_admin':
          return (const Color(0xFFEDE9FE), const Color(0xFF5B21B6));
        case 'admin':
          return (const Color(0xFFF5F3FF), const Color(0xFF6D28D9));
        case 'hr':
          return (const Color(0xFFCCFBF1), const Color(0xFF0F766E));
        case 'manager':
          return (const Color(0xFFEFF6FF), primaryDark);
        case 'team_lead':
          return (const Color(0xFFFFFBEB), const Color(0xFFB45309));
        case 'employee':
        default:
          return (const Color(0xFFF1F5F9), const Color(0xFF334155));
      }
    }
  }

  // Status Badge Styling Helper (Adaptive!)
  static (Color bg, Color fg) statusPillColors(bool isActive) {
    if (isActive) {
      return _isDark
          ? (const Color(0xFF064E3B), const Color(0xFF6EE7B7))
          : (const Color(0xFFECFDF5), const Color(0xFF047857));
    }
    return _isDark
        ? (const Color(0xFF1E293B), const Color(0xFF94A3B8))
        : (const Color(0xFFF1F5F9), const Color(0xFF64748B));
  }
}

class AppTheme {
  /// Ultra-clean, modern Light Theme
  static ThemeData get light {
    const surfaceColor = Colors.white;
    const bgColor = Color(0xFFF8FAFC);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimaryColor = Color(0xFF0F172A);
    const textSecondaryColor = Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFEFF6FF),
        onPrimaryContainer: const Color(0xFF1D4ED8),
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        onSurfaceVariant: textSecondaryColor,
        outline: borderColor,
        outlineVariant: const Color(0xFFF1F5F9),
        error: AppColors.rose,
        errorContainer: const Color(0xFFFEF2F2),
        onErrorContainer: const Color(0xFF991B1B),
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rose),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: const Color(0xFFEFF6FF),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.primary : textSecondaryColor,
          ),
        ),
      ),
    );
  }

  /// Luxury, sleek Obsidian Dark Theme (Linear / Vercel aesthetic)
  static ThemeData get dark {
    const surfaceColor = Color(0xFF131C2E);
    const bgColor = Color(0xFF0B0F19);
    const borderColor = Color(0xFF1E293B);
    const textPrimaryColor = Color(0xFFF8FAFC);
    const textSecondaryColor = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
        onPrimaryContainer: const Color(0xFFBFDBFE),
        secondary: const Color(0xFF818CF8),
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        onSurfaceVariant: textSecondaryColor,
        outline: borderColor,
        outlineVariant: const Color(0xFF162032),
        error: const Color(0xFFF87171),
        errorContainer: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
        onErrorContainer: const Color(0xFFFECACA),
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B0F19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0B0F19),
        indicatorColor: const Color(0xFF1E3A8A).withValues(alpha: 0.5),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.primaryLight : textSecondaryColor,
          ),
        ),
      ),
    );
  }
}