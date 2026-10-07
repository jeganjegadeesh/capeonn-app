import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<List<ConversationModel>> getConversations({
    String? search,
    String? type,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': 50,
      };
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      if (type != null && type.isNotEmpty && type != 'all') {
        params['type'] = type;
      }

      final res = await _dio.get('/conversations', queryParameters: params);
      final rawList = res.data['data'] as List? ?? [];
      return rawList
          .whereType<Map>()
          .map((c) => ConversationModel.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> getUnreadSummary() async {
    try {
      final res = await _dio.get('/conversations/unread-summary');
      return (res.data['data']?['total_unread'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationModel> getDirectConversation(int userId) async {
    try {
      final res = await _dio.post('/conversations/direct', data: {'user_id': userId});
      return ConversationModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationModel> createGroupConversation(
    String title,
    List<int> participantIds,
  ) async {
    try {
      final res = await _dio.post('/conversations/group', data: {
        'title': title,
        'participant_ids': participantIds,
      });
      return ConversationModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationModel> getProjectConversation(int projectId) async {
    try {
      final res = await _dio.get('/conversations/project/$projectId');
      return ConversationModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationModel> getConversation(int conversationId) async {
    try {
      final res = await _dio.get('/conversations/$conversationId');
      return ConversationModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ChatMessageModel>> getMessages(
    int conversationId, {
    int? beforeId,
    int page = 1,
    int perPage = 40,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (beforeId != null) params['before_id'] = beforeId;

      final res = await _dio.get('/conversations/$conversationId/messages', queryParameters: params);
      final rawList = res.data['data'] as List? ?? [];
      return rawList
          .whereType<Map>()
          .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatMessageModel> sendMessage(
    int conversationId, {
    String? message,
    int? replyToId,
    int? taskId,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (message != null && message.trim().isNotEmpty) {
        body['message'] = message.trim();
      }
      if (replyToId != null) body['reply_to_id'] = replyToId;
      if (taskId != null) body['task_id'] = taskId;
      if (attachments != null && attachments.isNotEmpty) {
        body['attachments'] = attachments;
      }

      final res = await _dio.post('/conversations/$conversationId/messages', data: body);
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAsRead(int conversationId, {int? lastReadMessageId}) async {
    try {
      final data = <String, dynamic>{};
      if (lastReadMessageId != null) {
        data['last_read_message_id'] = lastReadMessageId;
      }
      await _dio.post('/conversations/$conversationId/read', data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendTyping(int conversationId, bool isTyping) async {
    try {
      await _dio.post('/conversations/$conversationId/typing', data: {
        'is_typing': isTyping,
      });
    } catch (_) {
      // Ignore background typing broadcast failures
    }
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    try {
      await _dio.delete('/conversations/$conversationId/messages/$messageId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ChatMessageModel>> searchMessages(String query) async {
    try {
      final res = await _dio.get('/conversations/search', queryParameters: {'q': query});
      final rawList = res.data['data'] as List? ?? [];
      return rawList
          .whereType<Map>()
          .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatAttachmentModel> uploadAttachment(
    List<int> bytes,
    String fileName, {
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
      final data = res.data['data'] as Map;
      return ChatAttachmentModel(
        id: 0,
        fileName: fileName,
        filePath: data['path'] as String,
        fileSize: bytes.length,
        mimeType: mimeType ?? 'application/octet-stream',
        url: data['url'] as String,
        createdAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationModel> addParticipants(int conversationId, List<int> userIds) async {
    try {
      final res = await _dio.post('/conversations/$conversationId/participants', data: {
        'user_ids': userIds,
      });
      return ConversationModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeParticipant(int conversationId, int userId) async {
    try {
      await _dio.delete('/conversations/$conversationId/participants/$userId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatMessageModel> editMessage(int conversationId, int messageId, String newText) async {
    try {
      final res = await _dio.put('/conversations/$conversationId/messages/$messageId', data: {
        'message': newText,
      });
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatMessageModel> pinMessage(int conversationId, int messageId) async {
    try {
      final res = await _dio.post('/conversations/$conversationId/messages/$messageId/pin');
      return ChatMessageModel.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<bool> muteConversation(int conversationId, {bool? isMuted}) async {
    try {
      final data = isMuted != null ? {'is_muted': isMuted} : null;
      final res = await _dio.post('/conversations/$conversationId/mute', data: data);
      return res.data['data']['is_muted'] as bool? ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> leaveConversation(int conversationId) async {
    try {
      await _dio.post('/conversations/$conversationId/leave');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ChatMessageModel>> getTaskMessages(int taskId) async {
    try {
      final res = await _dio.get('/tasks/$taskId/messages');
      final rawList = res.data['data'] as List? ?? [];
      return rawList
          .whereType<Map>()
          .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
