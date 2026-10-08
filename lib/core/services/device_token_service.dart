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

  Future<void> registerDeviceToken({String? customToken}) async {
    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';
      
      final existingToken = await _tokenStorage.readKey(_deviceTokenKey);
      final token = customToken ?? existingToken ?? 'device_${platform}_${DateTime.now().millisecondsSinceEpoch}';

      await _dio.post('/device-tokens', data: {
        'token': token,
        'platform': platform,
      });

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
