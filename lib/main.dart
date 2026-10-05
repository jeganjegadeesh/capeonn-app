import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress known upstream Flutter Windows Alt-key / platform message assertions
  // that occur when Alt/Alt+Tab is pressed during window focus transitions.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exception.toString();
    if (message.contains('RawKeyDownEvent') ||
        message.contains('_keysPressed.isNotEmpty')) {
      return; // Ignore transient platform key assertion on Windows
    }
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  // Clean web URLs (/reset-password?token=...) instead of /#/reset-password,
  // so the link in the password-reset email opens the right screen.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: CapeonnApp()));
}

class CapeonnApp extends ConsumerWidget {
  const CapeonnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    AppColors.setDark(isDark);

    return MaterialApp.router(
      key: ValueKey('capeonn_app_${themeMode.name}_$isDark'),
      title: 'Capeonn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final currentDark = Theme.of(context).brightness == Brightness.dark;
        AppColors.setDark(currentDark);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}