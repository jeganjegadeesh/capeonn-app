import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'employee_model.dart';
import 'role_model.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(dioProvider));
});

class EmployeeRepository {
  EmployeeRepository(this._dio);

  final Dio _dio;

  Future<PaginatedEmployees> getEmployees({
    String? search,
    int? departmentId,
    int? reportsToId,
    String? role,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (departmentId != null) params['department_id'] = departmentId;
      if (reportsToId != null) params['reports_to_id'] = reportsToId;
      if (role != null && role.isNotEmpty) params['role'] = role;
      if (isActive != null) params['is_active'] = isActive ? 1 : 0;

      final res = await _dio.get('/employees', queryParameters: params);
      return PaginatedEmployees.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Employee> getEmployee(int id) async {
    try {
      final res = await _dio.get('/employees/$id');
      return Employee.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Employee> createEmployee(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/employees', data: data);
      return Employee.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Employee> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/employees/$id', data: data);
      return Employee.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _dio.delete('/employees/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<RoleItem>> getAssignableRoles() async {
    try {
      final res = await _dio.get('/roles');
      final raw = res.data['data'] as List? ?? [];
      return raw.map((r) => RoleItem.fromJson(Map<String, dynamic>.from(r as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
