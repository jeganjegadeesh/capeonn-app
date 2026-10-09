import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/features/tasks/data/task_comment_models.dart';
import 'package:capeonn_app/features/tasks/data/task_models.dart';

void main() {
  group('Phase 7 - Task Workflow & Comments Models', () {
    test('TaskCommentMentionModel correctly parses from JSON and serializes to JSON', () {
      final json = {'id': 15, 'name': 'Alex River'};
      final mention = TaskCommentMentionModel.fromJson(json);

      expect(mention.id, equals(15));
      expect(mention.name, equals('Alex River'));
      expect(mention.toJson(), equals(json));
    });

    test('TaskCommentModel correctly parses top-level comment with mentions and author', () {
      final commentJson = {
        'id': 101,
        'task_id': 50,
        'user_id': 7,
        'parent_id': null,
        'comment': 'Please review the updated frontend designs @AlexRiver',
        'attachments': ['uploads/spec.pdf'],
        'is_edited': true,
        'edited_at': '2026-10-09T10:00:00.000000Z',
        'created_at': '2026-10-09T09:30:00.000000Z',
        'updated_at': '2026-10-09T10:00:00.000000Z',
        'can_edit': true,
        'can_delete': false,
        'user': {
          'id': 7,
          'name': 'Sarah Developer',
          'email': 'sarah@capeonn.test',
          'avatar_url': 'http://capeonn.test/avatars/sarah.png',
          'role': {
            'name': 'Employee',
            'slug': 'employee',
          },
        },
        'mentions': [
          {'id': 15, 'name': 'Alex River'},
        ],
        'replies': [],
      };

      final comment = TaskCommentModel.fromJson(commentJson);

      expect(comment.id, equals(101));
      expect(comment.taskId, equals(50));
      expect(comment.userId, equals(7));
      expect(comment.isReply, isFalse);
      expect(comment.comment, contains('@AlexRiver'));
      expect(comment.isEdited, isTrue);
      expect(comment.canEdit, isTrue);
      expect(comment.canDelete, isFalse);
      expect(comment.userName, equals('Sarah Developer'));
      expect(comment.userRoleName, equals('Employee'));
      expect(comment.mentions.length, equals(1));
      expect(comment.mentions.first.name, equals('Alex River'));
      expect(comment.replies, isEmpty);
    });

    test('TaskCommentModel correctly parses nested threaded replies', () {
      final threadJson = {
        'id': 200,
        'task_id': 50,
        'user_id': 2,
        'parent_id': null,
        'comment': 'Has the database migration passed in CI?',
        'can_edit': false,
        'can_delete': false,
        'user': {
          'id': 2,
          'name': 'Marcus Lead',
          'role': {'name': 'Team Lead', 'slug': 'team_lead'},
        },
        'replies': [
          {
            'id': 201,
            'task_id': 50,
            'user_id': 7,
            'parent_id': 200,
            'comment': 'Yes, verified on staging with all tests green.',
            'can_edit': true,
            'can_delete': true,
            'user': {
              'id': 7,
              'name': 'Sarah Developer',
              'role': {'name': 'Employee', 'slug': 'employee'},
            },
            'replies': [],
          }
        ],
      };

      final parent = TaskCommentModel.fromJson(threadJson);
      expect(parent.isReply, isFalse);
      expect(parent.replies.length, equals(1));

      final reply = parent.replies.first;
      expect(reply.id, equals(201));
      expect(reply.parentId, equals(200));
      expect(reply.isReply, isTrue);
      expect(reply.userName, equals('Sarah Developer'));
      expect(reply.comment, contains('staging'));
    });

    test('TaskStatus values support Phase 7 review workflow states', () {
      expect(TaskStatus.review, equals('review'));
      expect(TaskStatus.changesRequired, equals('changes_required'));
      expect(TaskStatus.inProgress, equals('in_progress'));
      expect(TaskStatus.completed, equals('completed'));

      expect(TaskStatus.label('review'), equals('In Review'));
      expect(TaskStatus.label('changes_required'), equals('Changes Req.'));
      expect(TaskStatus.label('completed'), equals('Completed'));
    });

    test('TaskItem parses review and changes_required statuses accurately', () {
      final taskJson = {
        'id': 77,
        'project_id': 12,
        'title': 'Implement Workflow Audit Trail',
        'status': 'review',
        'priority': 'high',
        'actual_hours': 6.5,
        'estimated_hours': 8.0,
        'project': {
          'id': 12,
          'name': 'ERP Core 2.0',
        },
        'assigned_to': {
          'id': 9,
          'name': 'Elena Rostova',
        },
      };

      final task = TaskItem.fromJson(taskJson);
      expect(task.id, equals(77));
      expect(task.title, equals('Implement Workflow Audit Trail'));
      expect(task.status, equals(TaskStatus.review));
      expect(task.statusDisplay, equals('In Review'));
      expect(task.projectName, equals('ERP Core 2.0'));
      expect(task.assignedToName, equals('Elena Rostova'));
      expect(task.actualHours, equals(6.5));
    });
  });
}
