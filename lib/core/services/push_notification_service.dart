import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import '../router/app_router.dart';
import '../widgets/app_toast.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/application/notification_controller.dart';
import '../../features/tasks/presentation/widgets/task_detail_dialog.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling if needed (e.g. logging or local notification)
  if (kDebugMode) {
    print('FCM background message received: ${message.messageId}');
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  bool get isSupportedPlatform {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isSupportedPlatform) {
      if (kDebugMode) {
        print('FCM Push notifications not natively supported on this platform: $defaultTargetPlatform. Falling back to real-time WebSockets.');
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await _registerWindowsDeviceToken();
      }
      return;
    }

    try {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }

      // 1. Request permissions on iOS and Android 13+
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM permission authorization status: ${settings.authorizationStatus}');
      }

      // 2. Set foreground presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Retrieve and register token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }

      // 4. Token refresh listener
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _registerTokenWithBackend(newToken);
      });

      // 5. Foreground messages listener
      _foregroundSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 6. When notification is tapped while app is in background
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        handleNotificationTap(message.data);
      });

      // 7. Check if app was opened from terminated state by tapping a notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Small delay to allow router to initialize
        Future.delayed(const Duration(milliseconds: 600), () {
          handleNotificationTap(initialMessage.data);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('PushNotificationService initialization error: $e');
      }
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final platformStr = kIsWeb
          ? 'web'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'windows';

      await _ref.read(notificationRepositoryProvider).registerDeviceToken(
        token: token,
        platform: platformStr,
      );
      if (kDebugMode) {
        print('FCM device token registered with Capeonn backend.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register FCM device token: $e');
      }
    }
  }

  Future<void> _registerWindowsDeviceToken() async {
    try {
      final tokenStorage = _ref.read(tokenStorageProvider);
      const storageKey = 'capeonn_windows_device_token';
      var winToken = await tokenStorage.readKey(storageKey);
      if (winToken == null || winToken.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomPart = (timestamp % 1000000).toString().padLeft(6, '0');
        winToken = 'win_device_${timestamp}_$randomPart';
        await tokenStorage.writeKey(storageKey, winToken);
      }

      await _ref.read(notificationRepositoryProvider).registerDeviceToken(
        token: winToken,
        platform: 'windows',
        deviceName: 'Windows Desktop PC',
      );
      if (kDebugMode) {
        print('Windows desktop device registered with token: $winToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register Windows device token: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Invalidate unread count and list providers
    _ref.invalidate(notificationUnreadCountProvider);
    _ref.invalidate(notificationsListProvider);

    final title = message.notification?.title ?? message.data['title'] ?? 'Capeonn Notification';
    final body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

    final context = rootNavigatorKey.currentContext;
    if (context != null && body.isNotEmpty) {
      AppToast.showNotificationToast(
        context,
        title: title,
        message: body,
        onTap: () => handleNotificationTap(message.data),
      );
    }
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final taskIdStr = data['task_id'];
    final taskId = taskIdStr is num
        ? taskIdStr.toInt()
        : (taskIdStr is String ? int.tryParse(taskIdStr) : null);

    final convIdStr = data['conversation_id'];
    final conversationId = convIdStr is num
        ? convIdStr.toInt()
        : (convIdStr is String ? int.tryParse(convIdStr) : null);

    final projIdStr = data['project_id'];
    final projectId = projIdStr is num
        ? projIdStr.toInt()
        : (projIdStr is String ? int.tryParse(projIdStr) : null);

    if (taskId != null) {
      showDialog(
        context: context,
        builder: (_) => TaskDetailDialog(taskId: taskId),
      );
    } else if (conversationId != null) {
      GoRouter.of(context).push('/chat/$conversationId');
    } else if (projectId != null) {
      GoRouter.of(context).push('/projects/$projectId');
    }
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    _tokenRefreshSub?.cancel();
  }
}
