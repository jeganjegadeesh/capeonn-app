import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/report_models.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioProvider));
});

class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<DashboardSummaryData> getDashboardSummary(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/dashboard', queryParameters: filter.toQueryParams());
      return DashboardSummaryData.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EmployeeWorkloadReport> getEmployeeWorkload(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/workload', queryParameters: filter.toQueryParams());
      return EmployeeWorkloadReport.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TaskCompletionReport> getTaskCompletionReport(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/task-completion', queryParameters: filter.toQueryParams());
      return TaskCompletionReport.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TimeVarianceReport> getTimeVarianceReport(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/time-variance', queryParameters: filter.toQueryParams());
      return TimeVarianceReport.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<OverdueTasksReport> getOverdueTasksReport(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/overdue-tasks', queryParameters: filter.toQueryParams());
      return OverdueTasksReport.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectProgressReport> getProjectProgressReport(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/project-progress', queryParameters: filter.toQueryParams());
      return ProjectProgressReport.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TeamPerformanceReport> getTeamPerformanceReport(ReportFilter filter) async {
    try {
      final res = await _dio.get('/reports/team-performance', queryParameters: filter.toQueryParams());
      return TeamPerformanceReport.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> exportCsv(String type, ReportFilter filter) async {
    try {
      final params = filter.toQueryParams();
      params['type'] = type;
      final res = await _dio.get(
        '/reports/export',
        queryParameters: params,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/csv, text/plain, */*'},
        ),
      );
      return res.data?.toString() ?? '';
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
