import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  // ===========================================================================
  // BASE URL CONFIGURATION
  // Comment / Uncomment the line you need:
  // ===========================================================================

  // ---> DEV URL (Active)
  // static String get apiBaseUrl => devUrl;

  // ---> LOCAL URL (Uncomment line below and comment out DEV line above to use local)
  static String get apiBaseUrl => localUrl;

  // ===========================================================================
  // URL DEFINITIONS
  // ===========================================================================

  /// Remote Dev Server URL
  static const String devUrl = 'https://capeonn.jeganjegadeesh.in/api/v1';

  /// Local Server URL (10.0.2.2 on Android emulator, localhost on Web / Desktop / iOS)
  static String get localUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  /// Sent as `device_name` on login so sessions can be told apart later.
  static String get deviceName => kIsWeb ? 'web' : defaultTargetPlatform.name;

  // ===========================================================================
  // WEBSOCKET CONFIGURATION (Pusher / Soketi)
  // ===========================================================================

  /// WebSocket host (10.0.2.2 on Android emulator, 127.0.0.1 on Web / Desktop)
  static String get wsHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  /// WebSocket port (default Soketi/Pusher port is 6001)
  static const int wsPort = 6001;

  /// WebSocket scheme ('ws' or 'wss')
  static const String wsScheme = 'ws';

  /// Pusher/Soketi application key
  static const String wsKey = 'capeonn-app-key';

  /// Channel authorization endpoint
  static String get wsAuthUrl => '$apiBaseUrl/broadcasting/auth';
}
