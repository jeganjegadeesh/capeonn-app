import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Per-request switches, passed through Options(extra: {...}):
///   'auth': false       do not attach the token (login, forgot/reset password)
///   'suppress401': true a 401 here must not trigger the global "session expired" logout
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
    contentType: Headers.jsonContentType,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (options.extra['auth'] != false) {
        final token = await storage.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    },
    onError: (error, handler) {
      final hadToken = error.requestOptions.headers.containsKey('Authorization');
      final suppressed = error.requestOptions.extra['suppress401'] == true;

      // A 401 on a request that carried a token means the token expired or was revoked.
      if (error.response?.statusCode == 401 && hadToken && !suppressed) {
        ref.read(authControllerProvider.notifier).sessionExpired();
      }
      handler.next(error);
    },
  ));

  return dio;
});
