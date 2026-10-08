import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'chat_models.dart';

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository(ref.watch(dioProvider));
});

class PresenceRepository {
  PresenceRepository(this._dio);

  final Dio _dio;

  /// Send heartbeat to register the user as active and online
  Future<UserPresenceModel> sendHeartbeat() async {
    try {
      final res = await _dio.post('/presence/heartbeat');
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      return UserPresenceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Mark user as offline
  Future<UserPresenceModel> sendOffline() async {
    try {
      final res = await _dio.post('/presence/offline');
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      return UserPresenceModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Query presence for a set of users
  Future<List<UserPresenceModel>> getPresence({List<int>? userIds}) async {
    try {
      final params = <String, dynamic>{};
      if (userIds != null && userIds.isNotEmpty) {
        params['ids'] = userIds.join(',');
      }
      final res = await _dio.get('/presence', queryParameters: params);
      final rawList = res.data['data'] as List? ?? [];
      return rawList
          .whereType<Map>()
          .map((item) => UserPresenceModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<bool> updatePrivacy({required bool hidePresence}) async {
    try {
      final res = await _dio.put('/presence/privacy', data: {
        'hide_presence': hidePresence,
      });
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      return data['hide_presence'] as bool? ?? hidePresence;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
