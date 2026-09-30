import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'company_model.dart';
import 'department_model.dart';
import 'designation_model.dart';
import 'hierarchy_model.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(dioProvider));
});

class OrganizationRepository {
  OrganizationRepository(this._dio);

  final Dio _dio;

  Future<Company> getCompany() async {
    try {
      final res = await _dio.get('/company');
      return Company.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Company> updateCompany(Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/company', data: data);
      return Company.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Department>> getDepartments({
    String? search,
    bool? isActive,
    int perPage = 100,
  }) async {
    try {
      final params = <String, dynamic>{'per_page': perPage};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (isActive != null) params['is_active'] = isActive ? 1 : 0;

      final res = await _dio.get('/departments', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((d) => Department.fromJson(Map<String, dynamic>.from(d as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Department> createDepartment(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/departments', data: data);
      return Department.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Department> updateDepartment(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/departments/$id', data: data);
      return Department.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      await _dio.delete('/departments/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Designation>> getDesignations({
    String? search,
    bool? isActive,
    int perPage = 100,
  }) async {
    try {
      final params = <String, dynamic>{'per_page': perPage};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (isActive != null) params['is_active'] = isActive ? 1 : 0;

      final res = await _dio.get('/designations', queryParameters: params);
      final raw = res.data['data'] as List? ?? [];
      return raw.map((d) => Designation.fromJson(Map<String, dynamic>.from(d as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Designation> createDesignation(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/designations', data: data);
      return Designation.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Designation> updateDesignation(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/designations/$id', data: data);
      return Designation.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteDesignation(int id) async {
    try {
      await _dio.delete('/designations/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<HierarchyNode>> getHierarchy({bool includeInactive = false}) async {
    try {
      final res = await _dio.get('/hierarchy', queryParameters: {
        if (includeInactive) 'include_inactive': 1,
      });
      final raw = res.data['data'] as List? ?? [];
      return raw.map((h) => HierarchyNode.fromJson(Map<String, dynamic>.from(h as Map))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
