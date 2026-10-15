import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../../../../provider/auth/auth_user.dart';
import '../../../core/services/app_permission_service.dart';
import '../../../core/services/device_token_service.dart';
import '../../../core/services/push_notification_service.dart';

/// App-wide sign-in state:
///   loading        checking the saved token on start-up
///   data(null)     signed out
///   data(user)     signed in
///   error          server unreachable on start-up (the splash screen offers "Retry")
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final user = await ref.read(authRepositoryProvider).restore();
    if (user != null) {
      AppPermissionService.requestNotificationPermission();
    }
    return user;
  }

  /// Throws ApiException on failure so the login form can show the message.
  /// Deliberately does not switch to `loading`: that would rebuild the router and wipe the form.
  Future<void> login({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = AsyncData(user);
    AppPermissionService.requestNotificationPermission();

    try {
      await ref.read(pushNotificationServiceProvider).initialize();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error initializing push notifications: $e');
      }
    }
  }

  Future<void> logout() async {
    await ref.read(deviceTokenServiceProvider).unregisterDeviceToken();
    ref.read(pushNotificationServiceProvider).reset();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Uploads and updates the user's avatar.
  Future<AuthUser> uploadAvatar(List<int> bytes, String fileName) async {
    final user = await ref.read(authRepositoryProvider).uploadAvatar(bytes, fileName);
    state = AsyncData(user);
    return user;
  }

  /// Deletes the user's avatar.
  Future<AuthUser> deleteAvatar() async {
    final user = await ref.read(authRepositoryProvider).deleteAvatar();
    state = AsyncData(user);
    return user;
  }

  /// Refreshes the user profile from the server.
  Future<void> refreshUser() async {
    final user = await ref.read(authRepositoryProvider).restore();
    if (user != null) {
      state = AsyncData(user);
    }
  }

  /// Called by the HTTP layer when the server rejects our token (expired or revoked).
  Future<void> sessionExpired() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}
