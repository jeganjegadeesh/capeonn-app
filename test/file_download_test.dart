import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/core/config/app_config.dart';
import 'package:capeonn_app/features/chat/data/chat_models.dart';

void main() {
  group('File Download & URL Resolution Tests', () {
    test('AppConfig.resolveFileUrl correctly formats relative storage paths', () {
      final resolved = AppConfig.resolveFileUrl('/storage/uploads/photo.jpg');
      expect(resolved.startsWith('http'), isTrue);
      expect(resolved.endsWith('/storage/uploads/photo.jpg'), isTrue);
    });

    test('AppConfig.resolveFileUrl preserves already absolute URLs', () {
      const url = 'https://s3.amazonaws.com/bucket/doc.pdf';
      final resolved = AppConfig.resolveFileUrl(url);
      expect(resolved, equals(url));
    });

    test('ChatAttachmentModel resolves relative URLs upon JSON parsing', () {
      final json = {
        'id': 10,
        'file_name': 'project_specs.pdf',
        'file_path': 'uploads/project_specs.pdf',
        'file_size': 204800,
        'mime_type': 'application/pdf',
        'url': '/storage/uploads/project_specs.pdf',
      };

      final model = ChatAttachmentModel.fromJson(json);
      expect(model.id, equals(10));
      expect(model.fileName, equals('project_specs.pdf'));
      expect(model.isPdf, isTrue);
      expect(model.url.startsWith('http'), isTrue);
      expect(model.url.contains('/storage/uploads/project_specs.pdf'), isTrue);
    });

    test('ProjectFileModel resolves relative URLs upon JSON parsing', () {
      final json = {
        'id': 25,
        'project_id': 3,
        'file_name': 'architecture_diagram.png',
        'file_path': 'projects/3/architecture_diagram.png',
        'file_size': 1048576,
        'mime_type': 'image/png',
        'category': 'design',
        'url': '/storage/projects/3/architecture_diagram.png',
      };

      final model = ProjectFileModel.fromJson(json);
      expect(model.id, equals(25));
      expect(model.isImage, isTrue);
      expect(model.url.startsWith('http'), isTrue);
      expect(model.url.contains('/storage/projects/3/architecture_diagram.png'), isTrue);
    });
  });
}
