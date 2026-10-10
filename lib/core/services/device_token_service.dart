import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

class DeviceTokenService {
  DeviceTokenService(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;
  static const _deviceTokenKey = 'capeonn_device_token';

  Future<void> registerDeviceToken({String? customToken, String? deviceName}) async {
    try {
      if (customToken == null || customToken.trim().isEmpty) {
        // Only register valid native/FCM device tokens
        return;
      }
      final token = customToken.trim();

      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : Platform.isWindows
                  ? 'windows'
                  : 'android';

      final payload = <String, dynamic>{
        'token': token,
        'platform': platform,
      };
      if (deviceName != null) {
        payload['device_name'] = deviceName;
      }
      await _dio.post('/device-tokens', data: payload);

      await _tokenStorage.writeKey(_deviceTokenKey, token);
    } catch (_) {
      // Ignore background registration errors
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final token = await _tokenStorage.readKey(_deviceTokenKey);
      if (token != null && token.isNotEmpty) {
        await _dio.delete('/device-tokens', data: {'token': token});
        await _tokenStorage.deleteKey(_deviceTokenKey);
      }
    } catch (_) {
      // Ignore background deregistration errors
    }
  }
}
