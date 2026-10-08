import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<PaginatedNotifications> getNotifications({
    bool? unreadOnly,
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (unreadOnly == true) {
        params['unread_only'] = 1;
      }

      final res = await _dio.get('/notifications', queryParameters: params);
      return PaginatedNotifications.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      final data = res.data['data'] as Map? ?? {};
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _dio.delete('/notifications/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
