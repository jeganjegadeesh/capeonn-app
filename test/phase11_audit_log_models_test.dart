import 'package:capeonn_app/features/admin_system/application/audit_log_controller.dart';
import 'package:capeonn_app/features/admin_system/domain/models/audit_log_item.dart';
import 'package:capeonn_app/features/admin_system/presentation/audit_logs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 11 — AuditLogItem Model Tests', () {
    test('parses full audit log JSON with user and metadata', () {
      final json = {
        'id': 42,
        'company_id': 1,
        'user_id': 10,
        'event': 'auth.password_change',
        'severity': 'warning',
        'description': 'User updated security credentials',
        'ip_address': '192.168.1.100',
        'user_agent': 'Mozilla/5.0 Chrome/120',
        'metadata': {
          'action': 'password_reset',
          'revoked_tokens_count': 3,
        },
        'created_at': '2026-10-14T12:00:00.000000Z',
        'user': {
          'id': 10,
          'name': 'Super Admin',
          'email': 'superadmin@capeonn.test',
        },
      };

      final item = AuditLogItem.fromJson(json);

      expect(item.id, 42);
      expect(item.event, 'auth.password_change');
      expect(item.severity, 'warning');
      expect(item.description, 'User updated security credentials');
      expect(item.ipAddress, '192.168.1.100');
      expect(item.userName, 'Super Admin');
      expect(item.userEmail, 'superadmin@capeonn.test');
      expect(item.metadata?['revoked_tokens_count'], 3);
      expect(item.createdAt.year, 2026);
    });

    test('parses system-generated audit log without user actor', () {
      final json = {
        'id': 99,
        'company_id': 1,
        'user_id': null,
        'event': 'system.backup',
        'severity': 'info',
        'description': 'Nightly database snapshot saved',
        'ip_address': null,
        'user_agent': null,
        'metadata': null,
        'created_at': '2026-10-14T03:00:00Z',
        'user': null,
      };

      final item = AuditLogItem.fromJson(json);

      expect(item.id, 99);
      expect(item.event, 'system.backup');
      expect(item.severity, 'info');
      expect(item.userName, isNull);
      expect(item.userEmail, isNull);
      expect(item.ipAddress, isNull);
      expect(item.metadata, isNull);
    });

    test('handles fallback defaults gracefully for corrupted JSON', () {
      final json = <String, dynamic>{};

      final item = AuditLogItem.fromJson(json);

      expect(item.id, 0);
      expect(item.event, 'system.event');
      expect(item.severity, 'info');
      expect(item.description, '');
      expect(item.userName, isNull);
    });
  });

  group('Phase 11 — Audit Filter State & Notifier Tests', () {
    test('AuditFilterState default values and copyWith', () {
      const state = AuditFilterState();
      expect(state.severity, 'all');
      expect(state.search, '');

      final updated = state.copyWith(severity: 'critical', search: 'login');
      expect(updated.severity, 'critical');
      expect(updated.search, 'login');

      final preserved = updated.copyWith(severity: 'warning');
      expect(preserved.severity, 'warning');
      expect(preserved.search, 'login');
    });

    test('AuditFilterNotifier updates state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(auditFilterProvider).severity, 'all');
      expect(container.read(auditFilterProvider).search, '');

      container.read(auditFilterProvider.notifier).setSeverity('critical');
      expect(container.read(auditFilterProvider).severity, 'critical');

      container.read(auditFilterProvider.notifier).setSearch('192.168');
      expect(container.read(auditFilterProvider).search, '192.168');
      expect(container.read(auditFilterProvider).severity, 'critical');

      container.read(auditFilterProvider.notifier).reset();
      expect(container.read(auditFilterProvider).severity, 'all');
      expect(container.read(auditFilterProvider).search, '');
    });
  });

  group('Phase 11 — AuditLogsPage Widget Tests', () {
    testWidgets('renders AuditLogsPage with logs list and filter chips', (tester) async {
      final mockLog = AuditLogItem(
        id: 1,
        event: 'auth.login',
        description: 'User logged in successfully',
        severity: 'info',
        userName: 'Admin User',
        userEmail: 'admin@capeonn.test',
        ipAddress: '127.0.0.1',
        createdAt: DateTime.now(),
        metadata: {'platform': 'Flutter Web'},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditLogsListProvider.overrideWith((ref) async => [mockLog]),
          ],
          child: const MaterialApp(
            home: AuditLogsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Audit & Security Logs'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('auth.login'), findsOneWidget);
      expect(find.text('User logged in successfully'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('127.0.0.1'), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);

      // Tap on card to open detail dialog
      await tester.tap(find.text('auth.login'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Event #1'), findsOneWidget);
      expect(find.text('Metadata Payload:'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Audit Event #1'), findsNothing);
    });
  });
}

