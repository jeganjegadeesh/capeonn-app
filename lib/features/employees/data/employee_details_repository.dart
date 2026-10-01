import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'employee_details_models.dart';

final employeeDetailsRepositoryProvider = Provider<EmployeeDetailsRepository>((ref) {
  return EmployeeDetailsRepository(ref.watch(dioProvider));
});

class EmployeeDetailsRepository {
  EmployeeDetailsRepository(this._dio);

  final Dio _dio;

  Future<List<EmployeeDocumentItem>> getDocuments(int employeeId) async {
    try {
      final res = await _dio.get('/employees/$employeeId/documents');
      final raw = res.data['data'] as List? ?? [];
      return raw.map((d) => EmployeeDocumentItem.fromJson(Map<String, dynamic>.from(d as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EmployeeDocumentItem> uploadDocument(int employeeId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/employees/$employeeId/documents', data: data);
      return EmployeeDocumentItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteDocument(int documentId) async {
    try {
      await _dio.delete('/documents/$documentId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<EmployeeHistoryItem>> getHistories(int employeeId) async {
    try {
      final res = await _dio.get('/employees/$employeeId/history');
      final raw = res.data['data'] as List? ?? [];
      return raw.map((h) => EmployeeHistoryItem.fromJson(Map<String, dynamic>.from(h as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EmployeeHistoryItem> addHistory(int employeeId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/employees/$employeeId/history', data: data);
      return EmployeeHistoryItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateProfile(int employeeId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/employees/$employeeId/profile', data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
