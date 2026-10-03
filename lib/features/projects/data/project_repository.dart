import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'project_models.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(dioProvider));
});

class ProjectRepository {
  ProjectRepository(this._dio);

  final Dio _dio;

  Future<PaginatedProjects> getProjects({
    String? search,
    int? departmentId,
    String? status,
    String? priority,
    int? teamLeadId,
    bool? myProjects,
    bool? isOverdue,
    bool? includeArchived,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      if (departmentId != null) params['department_id'] = departmentId;
      if (status != null && status.isNotEmpty && status != 'all') params['status'] = status;
      if (priority != null && priority.isNotEmpty && priority != 'all') params['priority'] = priority;
      if (teamLeadId != null) params['team_lead_id'] = teamLeadId;
      if (myProjects == true) params['my_projects'] = 1;
      if (isOverdue == true) params['is_overdue'] = 1;
      if (includeArchived == true) params['include_archived'] = 1;

      final res = await _dio.get('/projects', queryParameters: params);
      return PaginatedProjects.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDashboardStats> getDashboard() async {
    try {
      final res = await _dio.get('/projects/dashboard');
      return ProjectDashboardStats.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> getProject(int id) async {
    try {
      final res = await _dio.get('/projects/$id');
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> createProject(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/projects', data: data);
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> updateProject(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/projects/$id', data: data);
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProject(int id) async {
    try {
      await _dio.delete('/projects/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> updateStatus(int projectId, {required String status, String? reason}) async {
    try {
      final res = await _dio.post('/projects/$projectId/status', data: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> requestCompletion(int projectId, {String? notes}) async {
    try {
      final res = await _dio.post('/projects/$projectId/request-completion', data: {
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> approveCompletion(int projectId) async {
    try {
      final res = await _dio.post('/projects/$projectId/approve-completion');
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> rejectCompletion(int projectId, {required String reason}) async {
    try {
      final res = await _dio.post('/projects/$projectId/reject-completion', data: {
        'reason': reason.trim(),
      });
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectDetail> assignLead(int projectId, int? teamLeadId, {String? reason, bool keepAsMember = true}) async {
    try {
      final res = await _dio.post('/projects/$projectId/lead', data: {
        'team_lead_id': teamLeadId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        'keep_as_member': keepAsMember,
      });
      return ProjectDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AddMemberResult> addMember(int projectId, int userId, String projectRole) async {
    try {
      final res = await _dio.post('/projects/$projectId/members', data: {
        'user_id': userId,
        'project_role': projectRole,
      });
      final dataMap = Map<String, dynamic>.from(res.data['data'] as Map);
      final rawWarnings = res.data['warnings'] as List<dynamic>? ?? [];
      final warnings = rawWarnings.map((w) => w.toString()).toList();

      return AddMemberResult(
        detail: ProjectDetail.fromJson(dataMap),
        warnings: warnings,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateMemberRole(int projectId, int memberUserId, String projectRole) async {
    try {
      await _dio.put('/projects/$projectId/members/$memberUserId', data: {
        'project_role': projectRole,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeMember(int projectId, int memberUserId) async {
    try {
      await _dio.delete('/projects/$projectId/members/$memberUserId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ProjectActivityItem>> getActivities(int projectId, {int page = 1}) async {
    try {
      final res = await _dio.get('/projects/$projectId/activities', queryParameters: {'page': page});
      final rawList = res.data['data'] as List<dynamic>? ?? [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((a) => ProjectActivityItem.fromJson(a))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
