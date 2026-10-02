import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

const _themePrefKey = 'capeonn_theme_mode';

/// Riverpod Provider that manages and persists the App's ThemeMode
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themePrefKey);
      if (saved == 'dark') {
        state = ThemeMode.dark;
        AppColors.setDark(true);
      } else if (saved == 'light') {
        state = ThemeMode.light;
        AppColors.setDark(false);
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    if (mode == ThemeMode.dark) {
      AppColors.setDark(true);
    } else if (mode == ThemeMode.light) {
      AppColors.setDark(false);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.dark) {
        await prefs.setString(_themePrefKey, 'dark');
      } else if (mode == ThemeMode.light) {
        await prefs.setString(_themePrefKey, 'light');
      } else {
        await prefs.remove(_themePrefKey);
      }
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentIsDark = isDarkActive(context);
    await setThemeMode(currentIsDark ? ThemeMode.light : ThemeMode.dark);
  }

  bool isDarkActive(BuildContext context) {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}

/// A compact, luxury animated theme switch button (Sun / Moon)
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({
    super.key,
    this.compact = false,
    this.showLabel = false,
  });

  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final isDark = notifier.isDarkActive(context);

    if (showLabel) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => notifier.toggleTheme(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  size: 18,
                  color: isDark ? const Color(0xFFFDE047) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IconButton(
      tooltip: isDark ? 'Switch to Light mode' : 'Switch to Dark mode',
      icon: Container(
        padding: EdgeInsets.all(compact ? 6 : 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey(isDark),
            size: compact ? 18 : 20,
            color: isDark ? const Color(0xFFFDE047) : const Color(0xFFF59E0B),
          ),
        ),
      ),
      onPressed: () => notifier.toggleTheme(context),
    );
  }
}

/// A sleek segmented theme selector (Light / System / Dark)
class ThemeSegmentedSwitch extends ConsumerWidget {
  const ThemeSegmentedSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    Widget buildOption({
      required ThemeMode itemMode,
      required IconData icon,
      required String label,
    }) {
      final isSelected = mode == itemMode;
      return Expanded(
        child: GestureDetector(
          onTap: () => notifier.setThemeMode(itemMode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          buildOption(itemMode: ThemeMode.light, icon: Icons.light_mode_rounded, label: 'Light'),
          buildOption(itemMode: ThemeMode.system, icon: Icons.settings_brightness_rounded, label: 'Auto'),
          buildOption(itemMode: ThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'Dark'),
        ],
      ),
    );
  }
}
