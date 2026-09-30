import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/features/organization/data/company_model.dart';
import 'package:capeonn_app/features/organization/data/department_model.dart';
import 'package:capeonn_app/features/organization/data/designation_model.dart';
import 'package:capeonn_app/features/organization/data/hierarchy_model.dart';

void main() {
  group('Organization Models', () {
    test('Company parses from JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'Capeonn Technologies',
        'code': 'CAP',
        'legal_name': 'Capeonn Technologies Private Limited',
        'email': 'contact@capeonn.com',
        'phone': '+1 555 0199',
        'address': '123 Tech Park',
        'timezone': 'Asia/Kolkata',
        'is_active': true,
        'departments_count': 4,
        'employees_count': 25,
      };

      final company = Company.fromJson(json);

      expect(company.id, 1);
      expect(company.name, 'Capeonn Technologies');
      expect(company.code, 'CAP');
      expect(company.legalName, 'Capeonn Technologies Private Limited');
      expect(company.departmentsCount, 4);
      expect(company.employeesCount, 25);
      expect(company.timezone, 'Asia/Kolkata');
      expect(company.isActive, isTrue);
    });

    test('Department parses head and employee count', () {
      final json = {
        'id': 10,
        'name': 'Engineering',
        'code': 'ENG',
        'description': 'Software Development and QA',
        'is_active': true,
        'head': {'id': 2, 'name': 'Meera Manager'},
        'employees_count': 12,
      };

      final dept = Department.fromJson(json);

      expect(dept.id, 10);
      expect(dept.name, 'Engineering');
      expect(dept.code, 'ENG');
      expect(dept.head?.id, 2);
      expect(dept.head?.name, 'Meera Manager');
      expect(dept.employeesCount, 12);
    });

    test('Designation parses correctly', () {
      final json = {
        'id': 3,
        'name': 'Senior Software Engineer',
        'is_active': true,
        'employees_count': 8,
      };

      final desig = Designation.fromJson(json);

      expect(desig.id, 3);
      expect(desig.name, 'Senior Software Engineer');
      expect(desig.isActive, isTrue);
      expect(desig.employeesCount, 8);
    });

    test('HierarchyNode calculates total reports recursively', () {
      final json = {
        'id': 1,
        'name': 'Meera Manager',
        'role': 'manager',
        'designation': 'Engineering Manager',
        'is_active': true,
        'reports': [
          {
            'id': 2,
            'name': 'Tara Lead',
            'role': 'team_lead',
            'designation': 'Team Lead',
            'is_active': true,
            'reports': [
              {
                'id': 3,
                'name': 'Eli Employee',
                'role': 'employee',
                'designation': 'Software Engineer',
                'is_active': true,
                'reports': [],
              },
              {
                'id': 4,
                'name': 'Esha Employee',
                'role': 'employee',
                'designation': 'Software Engineer',
                'is_active': true,
                'reports': [],
              },
            ],
          },
        ],
      };

      final manager = HierarchyNode.fromJson(json);

      expect(manager.reports.length, 1);
      expect(manager.reports.first.name, 'Tara Lead');
      expect(manager.reports.first.reports.length, 2);
      expect(manager.totalReportsCount, 3); // Tara + Eli + Esha
    });
  });
}
