// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/auth/data/auth_user.dart';

void main() {
  final json = {
    'id': 7,
    'name': 'Meera Manager',
    'email': 'manager@capeonn.test',
    'phone': null,
    'employee_code': 'CAP-0002',
    'is_active': true,
    'company': {'id': 1, 'name': 'Capeonn', 'code': 'CAP', 'timezone': 'Asia/Kolkata'},
    'department': {'id': 3, 'name': 'Engineering'},
    'designation': {'id': 2, 'name': 'Engineering Manager'},
    'role': {'slug': 'manager', 'name': 'Manager', 'level': 70},
    'reports_to': null,
    'permissions': {'employees.manage': 'department', 'projects.view': 'department'},
  };

  test('parses the user returned by the API', () {
    final user = AuthUser.fromJson(json);

    expect(user.id, 7);
    expect(user.roleSlug, 'manager');
    expect(user.roleLevel, 70);
    expect(user.companyName, 'Capeonn');
    expect(user.departmentName, 'Engineering');
    expect(user.reportsToName, isNull);
    expect(user.isAdmin, isFalse);
  });

  test('permission helpers use the scope map', () {
    final user = AuthUser.fromJson(json);

    expect(user.can('employees.manage'), isTrue);
    expect(user.can('organization.manage'), isFalse);
    expect(user.scopeOf('projects.view'), 'department');
    expect(user.scopeOf('nope'), isNull);
  });

  test('an empty permissions object (or list) means no permissions', () {
    expect(AuthUser.fromJson({...json, 'permissions': <String, dynamic>{}}).permissions, isEmpty);
    expect(AuthUser.fromJson({...json, 'permissions': <dynamic>[]}).permissions, isEmpty);
  });

  test('missing optional parts do not crash', () {
    final user = AuthUser.fromJson({'id': 1, 'name': 'A', 'email': 'a@b.co'});

    expect(user.roleSlug, '');
    expect(user.companyName, isNull);
    expect(user.permissions, isEmpty);
  });
}
