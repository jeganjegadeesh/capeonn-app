import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../chat/data/chat_models.dart';

final projectFilesRepositoryProvider = Provider<ProjectFilesRepository>((ref) {
  return ProjectFilesRepository(ref.watch(dioProvider));
});

class ProjectFilesRepository {
  ProjectFilesRepository(this._dio);

  final Dio _dio;

  Future<List<ProjectFileModel>> getProjectFiles(
    int projectId, {
    String? category,
    int? taskId,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': 50,
      };
      if (category != null && category.isNotEmpty && category != 'all') {
        params['category'] = category;
      }
      if (taskId != null) {
        params['task_id'] = taskId;
      }
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      final res = await _dio.get('/projects/$projectId/files', queryParameters: params);
      final rawList = res.data['data'] as List? ?? [];
      return rawList
          .whereType<Map>()
          .map((f) => ProjectFileModel.fromJson(Map<String, dynamic>.from(f)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProjectFileModel> uploadProjectFile(
    int projectId, {
    required List<int> fileBytes,
    required String fileName,
    String? category,
    int? taskId,
    String? description,
  }) async {
    try {
      final map = <String, dynamic>{
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      };
      if (category != null) map['category'] = category;
      if (taskId != null) map['task_id'] = taskId;
      if (description != null && description.trim().isNotEmpty) {
        map['description'] = description.trim();
      }

      final formData = FormData.fromMap(map);
      final res = await _dio.post('/projects/$projectId/files', data: formData);
      return ProjectFileModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProjectFile(int projectId, int fileId) async {
    try {
      await _dio.delete('/projects/$projectId/files/$fileId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
