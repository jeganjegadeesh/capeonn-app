import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'leave_models.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(dioProvider));
});

class LeaveRepository {
  LeaveRepository(this._dio);

  final Dio _dio;

  Future<List<LeaveType>> getTypes() async {
    try {
      final res = await _dio.get('/leaves/types');
      final raw = res.data['data'] as List? ?? [];
      return raw.map((t) => LeaveType.fromJson(Map<String, dynamic>.from(t as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<LeaveBalance>> getBalances({int? year, int? userId}) async {
    try {
      final params = <String, dynamic>{};
      if (year != null) params['year'] = year;
      if (userId != null) params['user_id'] = userId;

      final res = await _dio.get('/leaves/balances', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((b) => LeaveBalance.fromJson(Map<String, dynamic>.from(b as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<LeaveRequestItem>> getMyRequests({int page = 1}) async {
    try {
      final res = await _dio.get('/leaves/my-requests', queryParameters: {'page': page});
      final raw = res.data['data'] as List? ?? [];
      return raw.map((r) => LeaveRequestItem.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LeaveRequestItem> applyLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    bool isHalfDay = false,
    String? halfDayType,
    required String reason,
  }) async {
    try {
      final payload = <String, dynamic>{
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'is_half_day': isHalfDay,
        'reason': reason,
      };
      if (halfDayType != null) {
        payload['half_day_type'] = halfDayType;
      }
      final res = await _dio.post('/leaves/requests', data: payload);
      return LeaveRequestItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancelRequest(int id) async {
    try {
      await _dio.put('/leaves/requests/$id/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<LeaveRequestItem>> getRequests({String? status, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (status != null && status.isNotEmpty) params['status'] = status;

      final res = await _dio.get('/leaves/requests', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((r) => LeaveRequestItem.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> approveRequest(int id, {String? remarks}) async {
    try {
      await _dio.put('/leaves/requests/$id/approve', data: {
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> rejectRequest(int id, {String? remarks}) async {
    try {
      await _dio.put('/leaves/requests/$id/reject', data: {
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
