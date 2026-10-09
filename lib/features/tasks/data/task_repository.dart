import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../projects/data/project_models.dart';
import 'task_comment_models.dart';
import 'task_models.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});

class TaskRepository {
  TaskRepository(this._dio);

  final Dio _dio;

  /// GET /projects/{project}/tasks
  Future<List<TaskItem>> getProjectTasks(
    int projectId, {
    String? status,
    String? priority,
    String? assignedToId,
    bool? rootOnly,
    String? search,
    String? sortBy,
    String? sortDir,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'all') params['status'] = status;
      if (priority != null && priority.isNotEmpty && priority != 'all') params['priority'] = priority;
      if (assignedToId != null && assignedToId.isNotEmpty && assignedToId != 'all') {
        params['assigned_to_id'] = assignedToId;
      }
      if (rootOnly != null) params['root_only'] = rootOnly ? 1 : 0;
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      if (sortBy != null) params['sort_by'] = sortBy;
      if (sortDir != null) params['sort_dir'] = sortDir;

      final res = await _dio.get('/projects/$projectId/tasks', queryParameters: params);
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw.whereType<Map<String, dynamic>>().map((t) => TaskItem.fromJson(t)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/my
  Future<List<TaskItem>> getMyTasks({
    String? status,
    int? projectId,
    String? priority,
    bool? isOverdue,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'all') params['status'] = status;
      if (projectId != null) params['project_id'] = projectId;
      if (priority != null && priority.isNotEmpty && priority != 'all') params['priority'] = priority;
      if (isOverdue == true) params['is_overdue'] = 1;

      final res = await _dio.get('/tasks/my', queryParameters: params);
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw.whereType<Map<String, dynamic>>().map((t) => TaskItem.fromJson(t)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/{task}
  Future<TaskDetail> getTask(int taskId) async {
    try {
      final res = await _dio.get('/tasks/$taskId');
      return TaskDetail.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /projects/{project}/tasks
  Future<TaskItem> createTask(int projectId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/projects/$projectId/tasks', data: data);
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /tasks/{task}
  Future<TaskItem> updateTask(int taskId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/tasks/$taskId', data: data);
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /tasks/{task}
  Future<void> deleteTask(int taskId) async {
    try {
      await _dio.delete('/tasks/$taskId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/status
  Future<TaskItem> updateTaskStatus(int taskId, String status, {String? reason}) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (reason != null && reason.trim().isNotEmpty) {
        data['reason'] = reason.trim();
      }
      final res = await _dio.post('/tasks/$taskId/status', data: data);
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/assign
  Future<TaskItem> assignTask(int taskId, int? assignedToId, {String? reason}) async {
    try {
      final res = await _dio.post('/tasks/$taskId/assign', data: {
        'assigned_to_id': assignedToId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/{task}/subtasks
  Future<List<TaskItem>> getSubtasks(int taskId) async {
    try {
      final res = await _dio.get('/tasks/$taskId/subtasks');
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw.whereType<Map<String, dynamic>>().map((s) => TaskItem.fromJson(s)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/subtasks
  Future<TaskItem> createSubtask(int taskId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/tasks/$taskId/subtasks', data: data);
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Time Tracking Endpoints
  // ---------------------------------------------------------------------------

  /// POST /tasks/{task}/timer/start
  Future<TimeEntryItem> startTimer(int taskId, {String? description}) async {
    try {
      final data = <String, dynamic>{};
      if (description != null && description.isNotEmpty) data['description'] = description;
      final res = await _dio.post('/tasks/$taskId/timer/start', data: data);
      return TimeEntryItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/timer/stop
  Future<TimeEntryItem> stopTimer(int taskId, {String? description}) async {
    try {
      final data = <String, dynamic>{};
      if (description != null && description.isNotEmpty) data['description'] = description;
      final res = await _dio.post('/tasks/$taskId/timer/stop', data: data);
      return TimeEntryItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /time-entries/active
  Future<TimeEntryItem?> getActiveTimer() async {
    try {
      final res = await _dio.get('/time-entries/active');
      final data = res.data['data'];
      if (data == null) return null;
      return TimeEntryItem.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/time-entries
  Future<TimeEntryItem> storeManualTime(int taskId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/tasks/$taskId/time-entries', data: data);
      return TimeEntryItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /time-entries
  Future<List<TimeEntryItem>> getTimeEntries({
    int? projectId,
    int? taskId,
    int? userId,
    bool? isManual,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (projectId != null) params['project_id'] = projectId;
      if (taskId != null) params['task_id'] = taskId;
      if (userId != null) params['user_id'] = userId;
      if (isManual != null) params['is_manual'] = isManual ? 1 : 0;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;

      final res = await _dio.get('/time-entries', queryParameters: params);
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw.whereType<Map<String, dynamic>>().map((e) => TimeEntryItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/timer/pause
  Future<TimeEntryItem> pauseTimer(int taskId) async {
    try {
      final res = await _dio.post('/tasks/$taskId/timer/pause');
      return TimeEntryItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/timer/resume
  Future<TimeEntryItem> resumeTimer(int taskId) async {
    try {
      final res = await _dio.post('/tasks/$taskId/timer/resume');
      return TimeEntryItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/my-work-today
  Future<MyWorkTodaySummary> getMyWorkToday() async {
    try {
      final res = await _dio.get('/tasks/my-work-today');
      return MyWorkTodaySummary.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /timesheet
  Future<TimesheetData> getTimesheet({int? userId, String? dateFrom, String? dateTo}) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;

      final res = await _dio.get('/timesheet', queryParameters: params);
      return TimesheetData.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /timesheet/team
  Future<TeamTimesheetData> getTeamTimesheet({String? dateFrom, String? dateTo, int? projectId}) async {
    try {
      final params = <String, dynamic>{};
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (projectId != null) params['project_id'] = projectId;

      final res = await _dio.get('/timesheet/team', queryParameters: params);
      return TeamTimesheetData.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /time-entries/{entry}
  Future<void> deleteTimeEntry(int entryId) async {
    try {
      await _dio.delete('/time-entries/$entryId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ==========================================
  // Phase 7: Task Comments & Discussions
  // ==========================================

  /// GET /tasks/{task}/comments
  Future<List<TaskCommentModel>> getComments(int taskId) async {
    try {
      final res = await _dio.get('/tasks/$taskId/comments');
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((c) => TaskCommentModel.fromJson(c))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /uploads (upload attachment file for task comment)
  Future<Map<String, dynamic>> uploadAttachment({
    required List<int> bytes,
    required String fileName,
    String? mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final res = await _dio.post('/uploads', data: formData);
      return Map<String, dynamic>.from(res.data['data'] as Map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/comments
  Future<TaskCommentModel> addComment(
    int taskId, {
    required String comment,
    int? parentId,
    List<int>? mentions,
    List<dynamic>? attachments,
    List<int>? uploadIds,
  }) async {
    try {
      final data = <String, dynamic>{
        'comment': comment,
        'parent_id': ?parentId,
        if (mentions != null && mentions.isNotEmpty) 'mentions': mentions,
        if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
        if (uploadIds != null && uploadIds.isNotEmpty) 'upload_ids': uploadIds,
      };

      final res = await _dio.post('/tasks/$taskId/comments', data: data);
      return TaskCommentModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /tasks/{task}/comments/{comment}
  Future<TaskCommentModel> updateComment(
    int taskId,
    int commentId, {
    required String comment,
  }) async {
    try {
      final res = await _dio.put(
        '/tasks/$taskId/comments/$commentId',
        data: {'comment': comment},
      );
      return TaskCommentModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /tasks/{task}/comments/{comment}
  Future<void> deleteComment(int taskId, int commentId) async {
    try {
      await _dio.delete('/tasks/$taskId/comments/$commentId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/{task}/comments/{comment}/history
  Future<List<TaskCommentEditModel>> getCommentHistory(int taskId, int commentId) async {
    try {
      final res = await _dio.get('/tasks/$taskId/comments/$commentId/history');
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((c) => TaskCommentEditModel.fromJson(c))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ==========================================
  // Phase 7: Workflow & Approval Actions
  // ==========================================

  /// POST /tasks/{task}/submit-for-review
  Future<TaskItem> submitForReview(int taskId, {String? notes}) async {
    try {
      final res = await _dio.post(
        '/tasks/$taskId/submit-for-review',
        data: notes != null && notes.isNotEmpty ? {'notes': notes} : {},
      );
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/approve
  Future<TaskItem> approveTask(int taskId) async {
    try {
      final res = await _dio.post('/tasks/$taskId/approve');
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/request-changes
  Future<TaskItem> requestChanges(int taskId, {required String reason}) async {
    try {
      final res = await _dio.post(
        '/tasks/$taskId/request-changes',
        data: {'reason': reason},
      );
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/reopen
  Future<TaskItem> reopenTask(int taskId, {required String reason}) async {
    try {
      final res = await _dio.post(
        '/tasks/$taskId/reopen',
        data: {'reason': reason},
      );
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /tasks/{task}/reassign
  Future<TaskItem> reassignTask(
    int taskId, {
    required int newAssigneeId,
    String? reason,
  }) async {
    try {
      final res = await _dio.post(
        '/tasks/$taskId/reassign',
        data: {
          'assigned_to_id': newAssigneeId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return TaskItem.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/review-queue
  Future<List<TaskItem>> getReviewQueue({int? projectId, int? assignedToId, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (projectId != null) params['project_id'] = projectId;
      if (assignedToId != null) params['assigned_to_id'] = assignedToId;

      final res = await _dio.get('/tasks/review-queue', queryParameters: params);
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw.whereType<Map<String, dynamic>>().map((t) => TaskItem.fromJson(t)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /tasks/{task}/activities
  Future<List<ProjectActivityItem>> getTaskActivities(int taskId, {String? action, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (action != null && action.isNotEmpty && action != 'all') params['action'] = action;

      final res = await _dio.get('/tasks/$taskId/activities', queryParameters: params);
      final raw = res.data['data'] as List<dynamic>? ?? [];
      return raw.whereType<Map<String, dynamic>>().map((a) => ProjectActivityItem.fromJson(a)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
