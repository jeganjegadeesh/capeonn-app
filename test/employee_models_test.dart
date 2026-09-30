import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/features/employees/data/employee_model.dart';
import 'package:capeonn_app/features/employees/data/role_model.dart';

void main() {
  group('Employee Models', () {
    test('RoleItem parses correctly', () {
      final json = {
        'id': 2,
        'name': 'Manager',
        'slug': 'manager',
        'level': 70,
        'description': 'Department manager',
      };

      final role = RoleItem.fromJson(json);

      expect(role.id, 2);
      expect(role.name, 'Manager');
      expect(role.slug, 'manager');
      expect(role.level, 70);
      expect(role.description, 'Department manager');
    });

    test('Employee parses nested references and getters', () {
      final json = {
        'id': 5,
        'name': 'Esha Employee',
        'email': 'esha@capeonn.test',
        'phone': '1234567890',
        'employee_code': 'CAP-0005',
        'is_active': true,
        'joined_on': '2026-01-15',
        'last_login_at': '2026-03-01T10:00:00Z',
        'department': {'id': 1, 'name': 'Engineering'},
        'designation': {'id': 3, 'name': 'Software Engineer'},
        'role': {'id': 4, 'name': 'Employee', 'slug': 'employee', 'level': 10},
        'reports_to': {'id': 3, 'name': 'Tara Lead'},
      };

      final emp = Employee.fromJson(json);

      expect(emp.id, 5);
      expect(emp.name, 'Esha Employee');
      expect(emp.email, 'esha@capeonn.test');
      expect(emp.employeeCode, 'CAP-0005');
      expect(emp.isActive, isTrue);
      expect(emp.departmentName, 'Engineering');
      expect(emp.designationName, 'Software Engineer');
      expect(emp.roleName, 'Employee');
      expect(emp.roleSlug, 'employee');
      expect(emp.reportsToName, 'Tara Lead');
      expect(emp.departmentId, 1);
      expect(emp.designationId, 3);
      expect(emp.roleId, 4);
      expect(emp.reportsToId, 3);
    });

    test('PaginatedEmployees parses page metadata and items', () {
      final json = {
        'data': [
          {
            'id': 1,
            'name': 'Alice',
            'email': 'alice@test.com',
            'is_active': true,
          },
          {
            'id': 2,
            'name': 'Bob',
            'email': 'bob@test.com',
            'is_active': true,
          },
        ],
        'meta': {
          'current_page': 2,
          'last_page': 5,
          'per_page': 10,
          'total': 45,
        },
      };

      final paginated = PaginatedEmployees.fromJson(json);

      expect(paginated.items.length, 2);
      expect(paginated.currentPage, 2);
      expect(paginated.lastPage, 5);
      expect(paginated.perPage, 10);
      expect(paginated.total, 45);
      expect(paginated.hasNextPage, isTrue);
      expect(paginated.hasPrevPage, isTrue);
    });
  });
}
