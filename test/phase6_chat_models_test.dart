import 'package:capeonn_app/features/chat/data/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6 - Internal Chat & File Sharing Models', () {
    test('ChatAttachmentModel correctly parses and formats sizes and types', () {
      final imgAtt = ChatAttachmentModel.fromJson({
        'id': 1,
        'file_name': 'architecture_diagram.PNG',
        'file_path': 'chat/attachments/arch.png',
        'file_size': 1500000, // ~1.4 MB
        'mime_type': 'image/png',
        'url': 'http://capeonn.test/storage/chat/attachments/arch.png',
      });

      expect(imgAtt.id, equals(1));
      expect(imgAtt.fileName, equals('architecture_diagram.PNG'));
      expect(imgAtt.isImage, isTrue);
      expect(imgAtt.isPdf, isFalse);
      expect(imgAtt.formattedSize, equals('1.4 MB'));

      final pdfAtt = ChatAttachmentModel.fromJson({
        'id': 2,
        'file_name': 'sow_contract.pdf',
        'file_path': 'chat/attachments/sow.pdf',
        'file_size': 45056, // 44 KB
        'mime_type': 'application/pdf',
        'url': 'http://capeonn.test/storage/chat/attachments/sow.pdf',
      });

      expect(pdfAtt.isImage, isFalse);
      expect(pdfAtt.isPdf, isTrue);
      expect(pdfAtt.formattedSize, equals('44.0 KB'));

      final smallAtt = ChatAttachmentModel.fromJson({
        'id': 3,
        'file_name': 'readme.txt',
        'file_path': 'chat/attachments/readme.txt',
        'file_size': 512,
        'mime_type': 'text/plain',
        'url': 'http://capeonn.test/storage/chat/attachments/readme.txt',
      });

      expect(smallAtt.formattedSize, equals('512 B'));
    });

    test('ChatMessageModel correctly parses messages with reply, task links and attachments', () {
      final msgJson = {
        'id': 101,
        'conversation_id': 5,
        'user_id': 12,
        'message': 'Please review the updated deliverables for this milestone.',
        'type': 'text',
        'user': {
          'id': 12,
          'name': 'Sarah Connor',
          'role': {'slug': 'team_lead', 'name': 'Team Lead'},
        },
        'reply_to': {
          'id': 99,
          'message': 'Initial draft is submitted.',
          'user': {'name': 'John Reese'},
        },
        'task': {
          'id': 42,
          'title': 'Core API Architecture Design',
          'status': 'in_progress',
          'priority': 'high',
        },
        'attachments': [
          {
            'id': 1,
            'file_name': 'spec_v2.pdf',
            'file_path': 'chat/attachments/spec_v2.pdf',
            'file_size': 204800,
            'mime_type': 'application/pdf',
            'url': 'http://capeonn.test/storage/chat/attachments/spec_v2.pdf',
          }
        ],
        'is_edited': false,
        'created_at': '2026-10-05T12:00:00.000Z',
      };

      final msg = ChatMessageModel.fromJson(msgJson);

      expect(msg.id, equals(101));
      expect(msg.conversationId, equals(5));
      expect(msg.userId, equals(12));
      expect(msg.userName, equals('Sarah Connor'));
      expect(msg.userRoleSlug, equals('team_lead'));
      expect(msg.message, contains('review the updated deliverables'));
      expect(msg.isSystem, isFalse);
      expect(msg.replyToId, equals(99));
      expect(msg.replyToUserName, equals('John Reese'));
      expect(msg.replyToMessage, equals('Initial draft is submitted.'));
      expect(msg.hasTaskLink, isTrue);
      expect(msg.taskId, equals(42));
      expect(msg.taskTitle, equals('Core API Architecture Design'));
      expect(msg.hasAttachments, isTrue);
      expect(msg.attachments.length, equals(1));
      expect(msg.attachments.first.fileName, equals('spec_v2.pdf'));
    });

    test('ConversationModel parses direct, group, and project conversations', () {
      final directJson = {
        'id': 1,
        'type': 'direct',
        'title': null,
        'unread_count': 3,
        'participants': [
          {
            'id': 1,
            'user_id': 10,
            'role': 'member',
            'user': {'id': 10, 'name': 'Alice Engineer'},
          },
          {
            'id': 2,
            'user_id': 20,
            'role': 'member',
            'user': {'id': 20, 'name': 'Bob Designer'},
          },
        ],
        'last_message': {
          'id': 50,
          'message': 'See you at the sync meeting',
          'created_at': '2026-10-05T14:30:00.000Z',
          'user': {'id': 10, 'name': 'Alice Engineer'},
        },
        'can_post': true,
        'can_manage': false,
      };

      final direct = ConversationModel.fromJson(directJson);
      expect(direct.id, equals(1));
      expect(direct.isDirect, isTrue);
      expect(direct.isGroup, isFalse);
      expect(direct.isProject, isFalse);
      expect(direct.unreadCount, equals(3));
      expect(direct.canPost, isTrue);
      expect(direct.canManage, isFalse);
      expect(direct.displayTitle(10), equals('Bob Designer'));
      expect(direct.displayTitle(20), equals('Alice Engineer'));

      final groupJson = {
        'id': 2,
        'type': 'group',
        'title': 'Mobile Dev Squad',
        'unread_count': 0,
        'participants': [
          {'id': 1, 'user_id': 10, 'role': 'admin', 'user': {'id': 10, 'name': 'Alice'}},
          {'id': 2, 'user_id': 20, 'role': 'member', 'user': {'id': 20, 'name': 'Bob'}},
        ],
        'can_post': true,
        'can_manage': true,
      };

      final group = ConversationModel.fromJson(groupJson);
      expect(group.isGroup, isTrue);
      expect(group.displayTitle(10), equals('Mobile Dev Squad'));
      expect(group.canManage, isTrue);

      final projectJson = {
        'id': 3,
        'type': 'project',
        'project_id': 101,
        'project': {'id': 101, 'name': 'Enterprise Portal', 'code': 'PRJ-ENT'},
        'unread_count': 1,
        'can_post': true,
        'can_manage': false,
      };

      final projectConv = ConversationModel.fromJson(projectJson);
      expect(projectConv.isProject, isTrue);
      expect(projectConv.projectId, equals(101));
      expect(projectConv.projectName, equals('Enterprise Portal'));
      expect(projectConv.projectCode, equals('PRJ-ENT'));
      expect(projectConv.displayTitle(10), equals('Enterprise Portal'));
    });

    test('ProjectFileModel parses correctly with uploader and category helpers', () {
      final fileJson = {
        'id': 7,
        'project_id': 101,
        'user_id': 15,
        'task_id': 42,
        'file_name': 'Capeonn_Architecture_v1.docx',
        'file_path': 'projects/101/files/arch_v1.docx',
        'file_size': 2097152, // 2.0 MB
        'mime_type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'category': 'specification',
        'description': 'System high-level and detailed architecture specs',
        'url': 'http://capeonn.test/storage/projects/101/files/arch_v1.docx',
        'uploader': {
          'id': 15,
          'name': 'Dave Architect',
          'email': 'dave@capeonn.test',
        },
        'created_at': '2026-10-05T09:15:00.000Z',
      };

      final file = ProjectFileModel.fromJson(fileJson);
      expect(file.id, equals(7));
      expect(file.projectId, equals(101));
      expect(file.fileName, equals('Capeonn_Architecture_v1.docx'));
      expect(file.category, equals('specification'));
      expect(file.categoryDisplayName, equals('Specification'));
      expect(file.formattedSize, equals('2.0 MB'));
      expect(file.uploaderName, equals('Dave Architect'));
      expect(file.hasTaskLink, isTrue);
      expect(file.taskId, equals(42));
      expect(file.isDoc, isTrue);
      expect(file.isImage, isFalse);
      expect(file.isPdf, isFalse);
    });

    test('ChatMessageModel search results correctly parse and associate conversation IDs', () {
      final searchResults = [
        {
          'id': 201,
          'conversation_id': 12,
          'user_id': 5,
          'message': 'Meeting notes about Flutter architecture upgrade',
          'type': 'text',
          'user': {'id': 5, 'name': 'Lead Dev'},
          'created_at': '2026-10-06T10:00:00.000Z',
        },
        {
          'id': 202,
          'conversation_id': 14,
          'user_id': 8,
          'message': 'Uploaded architecture spec',
          'type': 'file',
          'user': {'id': 8, 'name': 'Designer'},
          'task': {'id': 99, 'title': 'Design Review'},
          'created_at': '2026-10-06T10:05:00.000Z',
        },
      ];

      final models = searchResults.map(ChatMessageModel.fromJson).toList();
      expect(models.length, equals(2));
      expect(models[0].conversationId, equals(12));
      expect(models[0].message, contains('Flutter architecture'));
      expect(models[0].hasTaskLink, isFalse);
      expect(models[1].conversationId, equals(14));
      expect(models[1].hasTaskLink, isTrue);
      expect(models[1].taskId, equals(99));
      expect(models[1].taskTitle, equals('Design Review'));
    });

    test('ConversationParticipantModel parses admin and member roles correctly', () {
      final p1 = ConversationParticipantModel.fromJson({
        'id': 1,
        'user_id': 10,
        'role': 'admin',
        'user': {'id': 10, 'name': 'Admin User', 'email': 'admin@test.com'},
      });
      final p2 = ConversationParticipantModel.fromJson({
        'id': 2,
        'user_id': 20,
        'role': 'member',
        'user': {'id': 20, 'name': 'Member User'},
      });

      expect(p1.isAdmin, isTrue);
      expect(p1.name, equals('Admin User'));
      expect(p2.isAdmin, isFalse);
      expect(p2.name, equals('Member User'));
    });

    test('ChatMessageModel parses pinned status and copyWith updates', () {
      final msg = ChatMessageModel.fromJson({
        'id': 201,
        'conversation_id': 10,
        'user_id': 5,
        'message': 'Pinned announcement',
        'is_pinned': true,
        'pinned_at': '2026-10-08T10:00:00.000Z',
        'pinned_by_name': 'Alice Manager',
        'is_edited': true,
      });

      expect(msg.isPinned, isTrue);
      expect(msg.pinnedByName, equals('Alice Manager'));
      expect(msg.isEdited, isTrue);

      final unpinned = msg.copyWith(isPinned: false);
      expect(unpinned.isPinned, isFalse);
      expect(unpinned.id, equals(201));
    });
  });
}
