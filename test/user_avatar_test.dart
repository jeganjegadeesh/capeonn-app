import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capeonn_app/core/widgets/user_avatar.dart';
import 'package:capeonn_app/features/employees/data/employee_model.dart';

void main() {
  group('UserAvatar Widget Tests', () {
    testWidgets('renders first initial of name when avatarUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: 'Jegadeesh Raja'),
          ),
        ),
      );

      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('renders ? when name is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: ''),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows camera edit badge when showEditBadge is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'Sarah Connor',
              showEditBadge: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('triggers onTap callback when avatar is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'Sarah Connor',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserAvatar));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onEditTap when edit badge is tapped', (tester) async {
      var editTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'Sarah Connor',
              showEditBadge: true,
              onEditTap: () => editTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      expect(editTapped, isTrue);
    });
  });

  group('Employee avatar parsing test', () {
    test('parses avatar_url and avatar_path in Employee', () {
      final emp = Employee.fromJson({
        'id': 10,
        'name': 'John Doe',
        'email': 'john@capeonn.test',
        'avatar_url': 'https://capeonn.test/storage/avatars/john.jpg',
        'avatar_path': 'avatars/john.jpg',
      });

      expect(emp.avatarUrl, 'https://capeonn.test/storage/avatars/john.jpg');
      expect(emp.avatarPath, 'avatars/john.jpg');
    });
  });
}
