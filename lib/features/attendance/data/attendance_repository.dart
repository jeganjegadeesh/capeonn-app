import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'attendance_models.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  Future<AttendanceToday> getToday() async {
    try {
      final res = await _dio.get('/attendance/today');
      return AttendanceToday.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AttendanceRecord> clockIn({
    double? latitude,
    double? longitude,
    String? locationName,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (locationName != null) data['location_name'] = locationName;
      if (notes != null) data['notes'] = notes;

      final res = await _dio.post('/attendance/clock-in', data: data);
      return AttendanceRecord.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AttendanceRecord> clockOut({
    double? latitude,
    double? longitude,
    String? locationName,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (locationName != null) data['location_name'] = locationName;
      if (notes != null) data['notes'] = notes;

      final res = await _dio.post('/attendance/clock-out', data: data);
      return AttendanceRecord.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<AttendanceRecord>> getMyRecords({
    int? month,
    int? year,
    int perPage = 31,
  }) async {
    try {
      final params = <String, dynamic>{'per_page': perPage};
      if (month != null) params['month'] = month;
      if (year != null) params['year'] = year;

      final res = await _dio.get('/attendance/my-records', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((r) => AttendanceRecord.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AttendanceSummary> getSummary({int? month, int? year}) async {
    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;
      if (year != null) params['year'] = year;

      final res = await _dio.get('/attendance/summary', queryParameters: params);
      return AttendanceSummary.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<AttendanceRecord>> getRecords({
    String? date,
    int? departmentId,
    int? userId,
    bool? isFlagged,
    String? status,
    int perPage = 50,
  }) async {
    try {
      final params = <String, dynamic>{'per_page': perPage};
      if (date != null) params['date'] = date;
      if (departmentId != null) params['department_id'] = departmentId;
      if (userId != null) params['user_id'] = userId;
      if (isFlagged != null) params['is_flagged'] = isFlagged ? 1 : 0;
      if (status != null) params['status'] = status;

      final res = await _dio.get('/attendance/records', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((r) => AttendanceRecord.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<AttendanceRegularization>> getRegularizations({
    String? status,
    int perPage = 50,
  }) async {
    try {
      final params = <String, dynamic>{'per_page': perPage};
      if (status != null && status.isNotEmpty) params['status'] = status;

      final res = await _dio.get('/attendance/regularizations', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((r) => AttendanceRegularization.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AttendanceRegularization> requestRegularization({
    required String date,
    required String requestedClockIn,
    required String requestedClockOut,
    required String reason,
  }) async {
    try {
      final res = await _dio.post('/attendance/regularizations', data: {
        'date': date,
        'requested_clock_in': requestedClockIn,
        'requested_clock_out': requestedClockOut,
        'reason': reason,
      });
      return AttendanceRegularization.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> approveRegularization(int id) async {
    try {
      await _dio.put('/attendance/regularizations/$id/approve');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> rejectRegularization(int id, {String? reason}) async {
    try {
      await _dio.put('/attendance/regularizations/$id/reject', data: {
        if (reason != null && reason.isNotEmpty) 'rejection_reason': reason,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
