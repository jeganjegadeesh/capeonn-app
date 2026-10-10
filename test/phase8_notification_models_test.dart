import 'package:capeonn_app/features/notifications/data/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8 — AppNotificationItem Tests', () {
    test('parses notification item and resolves task category and ids', () {
      final json = {
        'id': 101,
        'type': 'task_assigned',
        'title': 'New Task Assignment',
        'message': 'You were assigned to Implement FCM',
        'data': {
          'task_id': 45,
          'project_id': 12,
        },
        'read_at': null,
        'created_at': '2026-10-10T10:00:00Z',
      };

      final item = AppNotificationItem.fromJson(json);

      expect(item.id, 101);
      expect(item.type, 'task_assigned');
      expect(item.title, 'New Task Assignment');
      expect(item.body, 'You were assigned to Implement FCM');
      expect(item.taskId, 45);
      expect(item.projectId, 12);
      expect(item.conversationId, isNull);
      expect(item.isRead, isFalse);
      expect(item.category, NotificationCategory.tasks);
    });

    test('parses chat notification and resolves chat category and conversationId', () {
      final json = {
        'id': 102,
        'type': 'chat_mention',
        'title': 'Mentioned in Chat',
        'body': 'Sarah mentioned you in General',
        'data': {
          'conversation_id': '88',
          'message_id': 204,
        },
        'read_at': '2026-10-10T10:05:00Z',
        'created_at': '2026-10-10T10:04:00Z',
      };

      final item = AppNotificationItem.fromJson(json);

      expect(item.id, 102);
      expect(item.type, 'chat_mention');
      expect(item.conversationId, 88);
      expect(item.isRead, isTrue);
      expect(item.category, NotificationCategory.chat);
    });

    test('parses project notification and resolves projects category', () {
      final json = {
        'id': 103,
        'type': 'project_deadline_approaching',
        'title': 'Project Deadline',
        'message': 'Core Platform deadline is in 1 day',
        'data': {
          'project_id': 99,
        },
        'read_at': null,
      };

      final item = AppNotificationItem.fromJson(json);

      expect(item.id, 103);
      expect(item.projectId, 99);
      expect(item.category, NotificationCategory.projects);
    });
  });

  group('Phase 8 — PaginatedNotifications Tests', () {
    test('parses paginated notifications and meta', () {
      final json = {
        'data': [
          {
            'id': 1,
            'type': 'task_completed',
            'title': 'Task Done',
            'message': 'Approved by lead',
            'read_at': null,
          },
          {
            'id': 2,
            'type': 'chat_message',
            'title': 'Direct message',
            'message': 'Hello there',
            'read_at': '2026-10-10T10:00:00Z',
          },
        ],
        'meta': {
          'unread_count': 1,
          'total': 2,
          'current_page': 1,
          'last_page': 1,
        },
      };

      final paginated = PaginatedNotifications.fromJson(json);

      expect(paginated.items.length, 2);
      expect(paginated.unreadCount, 1);
      expect(paginated.total, 2);
      expect(paginated.items.first.title, 'Task Done');
      expect(paginated.items.first.isRead, isFalse);
      expect(paginated.items.last.isRead, isTrue);
    });
  });

  group('Phase 8 — NotificationPreferencesModel Tests', () {
    test('defaults are all enabled', () {
      final prefs = NotificationPreferencesModel.defaults();
      expect(prefs.pushEnabled, isTrue);
      expect(prefs.emailEnabled, isTrue);
      expect(prefs.taskAlerts, isTrue);
      expect(prefs.deadlineAlerts, isTrue);
      expect(prefs.chatAlerts, isTrue);
      expect(prefs.projectAlerts, isTrue);
    });

    test('fromJson and toJson round-trip', () {
      final json = {
        'push_enabled': false,
        'email_enabled': true,
        'task_alerts': true,
        'deadline_alerts': false,
        'chat_alerts': true,
        'project_alerts': false,
      };

      final prefs = NotificationPreferencesModel.fromJson(json);
      expect(prefs.pushEnabled, isFalse);
      expect(prefs.deadlineAlerts, isFalse);
      expect(prefs.projectAlerts, isFalse);
      expect(prefs.taskAlerts, isTrue);

      final outJson = prefs.toJson();
      expect(outJson, equals(json));
    });

    test('copyWith updates individual flags', () {
      final initial = NotificationPreferencesModel.defaults();
      final updated = initial.copyWith(
        pushEnabled: false,
        chatAlerts: false,
      );

      expect(updated.pushEnabled, isFalse);
      expect(updated.chatAlerts, isFalse);
      expect(updated.taskAlerts, isTrue);
      expect(updated.deadlineAlerts, isTrue);
    });
  });
}
