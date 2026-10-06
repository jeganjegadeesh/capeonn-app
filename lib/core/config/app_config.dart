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

  /// Resolves an asset/attachment URL to an absolute, reachable URL across all platforms.
  static String resolveFileUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final url = rawUrl.trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (url.contains('localhost:8000') || url.contains('127.0.0.1:8000')) {
          return url.replaceAll('localhost:8000', '10.0.2.2:8000').replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
        }
        if (url.contains('localhost') && !url.contains('10.0.2.2')) {
          return url.replaceAll('localhost', '10.0.2.2');
        }
      }
      return url;
    }

    // Relative path (e.g. /storage/uploads/xyz.png)
    final serverBase = apiBaseUrl.replaceAll('/api/v1', '');
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$serverBase$cleanPath';
  }

  // ===========================================================================
  // WEBSOCKET CONFIGURATION (Pusher / Soketi)
  // ===========================================================================

  /// Enable or disable WebSocket real-time transport.
  /// When true, attempts connection to wsHost:wsPort.
  /// If the WebSocket daemon is not running or unreachable, the app seamlessly
  /// falls back to automatic HTTP polling without errors or disruption.
  static const bool wsEnabled = true;

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
