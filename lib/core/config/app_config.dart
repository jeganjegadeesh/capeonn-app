import 'package:flutter/foundation.dart';

/// Supported WebSocket transports
enum WebSocketMode {
  /// Pusher.com Cloud (recommended for cPanel / Remote Dev Server)
  pusherCloud,

  /// Local Soketi / Reverb Daemon (for localhost development on port 6001)
  localServer,

  /// Disabled (operates purely via HTTP Polling fallback)
  disabled,
}

class AppConfig {
  AppConfig._();

  // ===========================================================================
  // BASE URL CONFIGURATION
  // Comment / Uncomment the line you need:
  // ===========================================================================

  // ---> DEV URL (Active)
  static String get apiBaseUrl => devUrl;

  // ---> LOCAL URL (Uncomment line below and comment out DEV line above to use local)
  // static String get apiBaseUrl => localUrl;

  // ===========================================================================
  // WEBSOCKET MODE CONFIGURATION
  // Comment / Uncomment ONE line below to switch modes:
  // ===========================================================================

  // ---> MODE 1: PUSHER.COM CLOUD (Active - For cPanel / Remote Dev Server)
  static const WebSocketMode wsMode = WebSocketMode.pusherCloud;

  // ---> MODE 2: LOCAL SOKETI / REVERB (Uncomment for Local Machine Development)
  // static const WebSocketMode wsMode = WebSocketMode.localServer;

  // ---> MODE 3: HTTP POLLING ONLY (Uncomment to disable WebSockets entirely)
  // static const WebSocketMode wsMode = WebSocketMode.disabled;

  // ===========================================================================
  // PUSHER.COM CLOUD SETTINGS
  // (Used when wsMode == WebSocketMode.pusherCloud)
  // ===========================================================================
  static const String pusherKey = 'a5ce3cd6f0f95243808a';
  static const String pusherCluster = 'ap2';

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
  static String resolveFileUrl(String? rawUrl, {String? token}) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    var url = rawUrl.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Relative path (e.g. /storage/uploads/xyz.png)
      final serverBase = apiBaseUrl.replaceAll('/api/v1', '');
      final cleanPath = url.startsWith('/') ? url : '/$url';
      url = '$serverBase$cleanPath';
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (url.contains('localhost:8000') || url.contains('127.0.0.1:8000')) {
        url = url.replaceAll('localhost:8000', '10.0.2.2:8000').replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
      }
      if (url.contains('localhost') && !url.contains('10.0.2.2')) {
        url = url.replaceAll('localhost', '10.0.2.2');
      }
    }

    // Append auth token if provided and not already present
    if (token != null && token.isNotEmpty && !url.contains('token=')) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}token=${Uri.encodeComponent(token)}';
    }

    return url;
  }

  // ===========================================================================
  // DYNAMIC WEBSOCKET RESOLUTION
  // Automatically resolves based on selected wsMode above
  // ===========================================================================

  /// Whether WebSocket real-time transport is active
  static bool get wsEnabled => wsMode != WebSocketMode.disabled;

  /// Pusher / Soketi application key
  static String get wsKey {
    switch (wsMode) {
      case WebSocketMode.pusherCloud:
        return pusherKey;
      case WebSocketMode.localServer:
        return 'capeonn-app-key';
      case WebSocketMode.disabled:
        return '';
    }
  }

  /// WebSocket host (Pusher cloud endpoint or localhost/emulator)
  static String get wsHost {
    switch (wsMode) {
      case WebSocketMode.pusherCloud:
        return 'ws-$pusherCluster.pusher.com';
      case WebSocketMode.localServer:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return '10.0.2.2';
        }
        return '127.0.0.1';
      case WebSocketMode.disabled:
        return '127.0.0.1';
    }
  }

  /// WebSocket port (443 for Pusher WSS, 6001 for local Soketi)
  static int get wsPort {
    switch (wsMode) {
      case WebSocketMode.pusherCloud:
        return 443;
      case WebSocketMode.localServer:
      case WebSocketMode.disabled:
        return 6001;
    }
  }

  /// WebSocket scheme ('wss' for SSL or 'ws')
  static String get wsScheme {
    switch (wsMode) {
      case WebSocketMode.pusherCloud:
        return 'wss';
      case WebSocketMode.localServer:
      case WebSocketMode.disabled:
        return 'ws';
    }
  }

  /// Channel authorization endpoint
  static String get wsAuthUrl => '$apiBaseUrl/broadcasting/auth';
}
