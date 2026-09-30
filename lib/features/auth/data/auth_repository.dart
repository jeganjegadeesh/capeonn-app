import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../provider/auth/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  /// Sends the request and returns the decoded body { success, message, data }.
  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      return body is Map<String, dynamic> ? body : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final body = await _send(() => _dio.post(
          '/auth/login',
          data: {
            'email': email.trim(),
            'password': password,
            'device_name': AppConfig.deviceName,
          },
          options: Options(extra: {'auth': false}),
        ));

    final data = body['data'] as Map<String, dynamic>;
    await _storage.write(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Called on app start. Returns the user if a saved token is still valid, otherwise null.
  /// Throws ApiException only for problems that are not "you are not signed in"
  /// (server down, no network), so the UI can offer a retry.
  Future<AuthUser?> restore() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return null;

    try {
      final body = await _send(() => _dio.get(
            '/auth/me',
            options: Options(extra: {'suppress401': true}),
          ));
      return AuthUser.fromJson(body['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isForbidden) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  /// Always clears the local token, even if the server call fails.
  Future<void> logout() async {
    try {
      await _send(() => _dio.post(
            '/auth/logout',
            options: Options(extra: {'suppress401': true}),
          ));
    } on ApiException {
      // Already signed out on the server, or offline. Either way we are done locally.
    } finally {
      await _storage.clear();
    }
  }

  /// Returns the server's confirmation message.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final body = await _send(() => _dio.post('/auth/change-password', data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        }));
    return body['message'] as String? ?? 'Password changed successfully';
  }

  Future<String> forgotPassword(String email) async {
    final body = await _send(() => _dio.post(
          '/auth/forgot-password',
          data: {'email': email.trim()},
          options: Options(extra: {'auth': false}),
        ));
    return body['message'] as String? ?? 'If that email is registered, a password reset message has been sent.';
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String confirmation,
  }) async {
    final body = await _send(() => _dio.post(
          '/auth/reset-password',
          data: {
            'email': email.trim(),
            'token': token.trim(),
            'password': password,
            'password_confirmation': confirmation,
          },
          options: Options(extra: {'auth': false}),
        ));
    return body['message'] as String? ?? 'Your password has been reset. You can now log in.';
  }
}
