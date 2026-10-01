import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'holiday_models.dart';

final holidayRepositoryProvider = Provider<HolidayRepository>((ref) {
  return HolidayRepository(ref.watch(dioProvider));
});

class HolidayRepository {
  HolidayRepository(this._dio);

  final Dio _dio;

  Future<List<HolidayItem>> getHolidays({int? year, bool upcoming = false}) async {
    try {
      final params = <String, dynamic>{};
      if (year != null) params['year'] = year;
      if (upcoming) params['upcoming'] = 1;

      final res = await _dio.get('/holidays', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((h) => HolidayItem.fromJson(Map<String, dynamic>.from(h as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<HolidayItem> createHoliday(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/holidays', data: data);
      return HolidayItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<HolidayItem> updateHoliday(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/holidays/$id', data: data);
      return HolidayItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteHoliday(int id) async {
    try {
      await _dio.delete('/holidays/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
