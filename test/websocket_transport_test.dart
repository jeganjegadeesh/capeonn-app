import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/core/config/app_config.dart';
import 'package:capeonn_app/features/chat/data/chat_models.dart';
import 'package:capeonn_app/features/chat/data/chat_websocket_service.dart';
import 'package:capeonn_app/features/chat/application/chat_controller.dart';

void main() {
  group('WebSocket Transport & Configuration Tests', () {
    test('AppConfig provides valid WebSocket settings', () {
      expect(AppConfig.wsPort, equals(6001));
      expect(AppConfig.wsScheme, equals('ws'));
      expect(AppConfig.wsKey, isNotEmpty);
      expect(AppConfig.wsHost, isNotEmpty);
      expect(AppConfig.wsAuthUrl, contains('/broadcasting/auth'));
    });

    test('ChatWebSocketService starts disconnected and disposes cleanly', () async {
      final service = ChatWebSocketService();
      expect(service.status, equals(WebSocketStatus.disconnected));

      final statuses = <WebSocketStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      await service.dispose();
      await sub.cancel();
      expect(service.status, equals(WebSocketStatus.disconnected));
    });

    test('ChatUserTypingData parses incoming Pusher event payloads', () {
      final json = {
        'conversation_id': 42,
        'user_id': 7,
        'user_name': 'Sarah Connor',
        'is_typing': true,
      };

      final data = ChatUserTypingData.fromJson(json);
      expect(data.conversationId, equals(42));
      expect(data.userId, equals(7));
      expect(data.userName, equals('Sarah Connor'));
      expect(data.isTyping, isTrue);
    });

    test('ChatMessageReadData parses incoming Pusher event payloads', () {
      final json = {
        'conversation_id': 42,
        'user_id': 7,
        'user_name': 'Sarah Connor',
        'last_read_message_id': 105,
        'read_at': '2026-10-06T12:00:00Z',
      };

      final data = ChatMessageReadData.fromJson(json);
      expect(data.conversationId, equals(42));
      expect(data.userId, equals(7));
      expect(data.userName, equals('Sarah Connor'));
      expect(data.lastReadMessageId, equals(105));
      expect(data.readAt, equals('2026-10-06T12:00:00Z'));
    });

    test('ChatRoomState correctly tracks real-time typing indicators', () {
      const conv = ConversationModel(
        id: 1,
        type: 'direct',
        title: null,
        displayName: 'Alice',
        participants: [],
      );

      final state = const ChatRoomState(
        conversation: conv,
        messages: [],
      );

      expect(state.isPartnerTyping, isFalse);
      expect(state.partnerTypingName, isNull);

      final typingState = state.copyWith(
        isPartnerTyping: true,
        partnerTypingName: 'Alice',
      );

      expect(typingState.isPartnerTyping, isTrue);
      expect(typingState.partnerTypingName, equals('Alice'));

      final stoppedState = typingState.copyWith(
        isPartnerTyping: false,
      );

      expect(stoppedState.isPartnerTyping, isFalse);
    });

    test('ChatMessageModel parses message.sent event payload', () {
      final payload = {
        'id': 99,
        'conversation_id': 12,
        'user_id': 3,
        'user_name': 'Bob Architect',
        'message': 'Hello from Soketi WebSocket!',
        'type': 'text',
        'attachments': [
          {
            'id': 1,
            'file_name': 'diagram.png',
            'file_path': 'uploads/diagram.png',
            'file_size': 204800,
            'mime_type': 'image/png',
            'url': 'https://capeonn.test/storage/uploads/diagram.png',
          }
        ],
      };

      final msg = ChatMessageModel.fromJson(payload);
      expect(msg.id, equals(99));
      expect(msg.conversationId, equals(12));
      expect(msg.message, equals('Hello from Soketi WebSocket!'));
      expect(msg.attachments.length, equals(1));
      expect(msg.attachments.first.isImage, isTrue);
      expect(msg.attachments.first.fileName, equals('diagram.png'));
    });
  });
}
