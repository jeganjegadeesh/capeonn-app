import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/features/chat/application/presence_controller.dart';
import 'package:capeonn_app/features/chat/data/chat_models.dart';

void main() {
  group('Live Online / Offline Presence Heartbeat Tests', () {
    test('UserPresenceModel correctly parses JSON payload', () {
      final json = {
        'user_id': 101,
        'user_name': 'Eleanor Vance',
        'is_online': true,
        'last_seen_at': '2026-10-06T14:30:00Z',
      };

      final model = UserPresenceModel.fromJson(json);
      expect(model.userId, equals(101));
      expect(model.userName, equals('Eleanor Vance'));
      expect(model.isOnline, isTrue);
      expect(model.lastSeenAt, isNotNull);
      expect(model.lastSeenAt!.year, equals(2026));

      final serialized = model.toJson();
      expect(serialized['user_id'], equals(101));
      expect(serialized['is_online'], isTrue);
    });

    test('ConversationParticipantModel parses presence fields', () {
      final json = {
        'user_id': 5,
        'name': 'Bob The Builder',
        'role': 'member',
        'is_online': true,
        'last_seen_at': '2026-10-06T15:00:00Z',
      };

      final participant = ConversationParticipantModel.fromJson(json);
      expect(participant.userId, equals(5));
      expect(participant.name, equals('Bob The Builder'));
      expect(participant.isOnline, isTrue);
      expect(participant.lastSeenAt, isNotNull);
    });

    test('ConversationModel parses direct partner presence fields', () {
      final json = {
        'id': 1,
        'type': 'direct',
        'display_name': 'Alice Wonder',
        'partner': {
          'id': 8,
          'name': 'Alice Wonder',
          'is_online': true,
          'last_seen_at': '2026-10-06T15:30:00Z',
        },
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.isDirect, isTrue);
      expect(conv.partnerId, equals(8));
      expect(conv.partnerName, equals('Alice Wonder'));
      expect(conv.partnerIsOnline, isTrue);
      expect(conv.partnerLastSeenAt, isNotNull);
    });

    test('PresenceState accurately computes online status and human-readable last seen', () {
      final now = DateTime.now();

      final onlineUser = UserPresenceModel(
        userId: 1,
        userName: 'Alice',
        isOnline: true,
        lastSeenAt: now,
      );

      final recentUser = UserPresenceModel(
        userId: 2,
        userName: 'Bob',
        isOnline: false,
        lastSeenAt: now.subtract(const Duration(minutes: 5)),
      );

      final hoursUser = UserPresenceModel(
        userId: 3,
        userName: 'Charlie',
        isOnline: false,
        lastSeenAt: now.subtract(const Duration(hours: 3)),
      );

      final state = PresenceState(
        users: {
          1: onlineUser,
          2: recentUser,
          3: hoursUser,
        },
      );

      expect(state.isUserOnline(1), isTrue);
      expect(state.isUserOnline(2), isFalse);
      expect(state.isUserOnline(99), isFalse);

      expect(state.formatPresence(1), equals('Online'));
      expect(state.formatPresence(2), equals('Active 5m ago'));
      expect(state.formatPresence(3), equals('Active 3h ago'));
      expect(state.formatPresence(99), equals('Offline'));
    });
  });
}
