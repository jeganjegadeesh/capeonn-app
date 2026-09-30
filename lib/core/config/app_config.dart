import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Override at build/run time, e.g. for a physical phone on your Wi-Fi:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches your computer's localhost through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    // Web, Windows, iOS simulator.
    return 'http://localhost:8000/api/v1';
  }

  /// Sent as `device_name` on login so sessions can be told apart later.
  static String get deviceName => kIsWeb ? 'web' : defaultTargetPlatform.name;
}
