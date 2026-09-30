import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../../../../provider/auth/auth_user.dart';

/// App-wide sign-in state:
///   loading        checking the saved token on start-up
///   data(null)     signed out
///   data(user)     signed in
///   error          server unreachable on start-up (the splash screen offers "Retry")
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() => ref.read(authRepositoryProvider).restore();

  /// Throws ApiException on failure so the login form can show the message.
  /// Deliberately does not switch to `loading`: that would rebuild the router and wipe the form.
  Future<void> login({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Called by the HTTP layer when the server rejects our token (expired or revoked).
  Future<void> sessionExpired() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}
