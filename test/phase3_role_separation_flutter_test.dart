import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/core/network/api_exception.dart';
import 'package:capeonn_app/features/auth/data/auth_user.dart';
import 'package:capeonn_app/features/leaves/data/leave_models.dart';
import 'package:capeonn_app/features/attendance/data/attendance_models.dart';

void main() {
  group('Phase 3 Role Separation - Flutter Auth & Models', () {
    test('Super Admin user model correctly hides attendance and leaves', () {
      final json = {
        'id': 1,
        'name': 'Super Admin',
        'email': 'admin@capeonn.test',
        'is_active': true,
        'is_attendance_applicable': false,
        'role': {
          'id': 1,
          'name': 'Super Admin',
          'slug': 'super_admin',
          'level': 100,
        },
        'permissions': {
          'roles.manage': 'all',
          'system.manage': 'all',
          'employees.manage': 'all',
        },
      };

      final user = AuthUser.fromJson(json);

      expect(user.isSuperAdmin, isTrue);
      expect(user.isAdmin, isTrue);
      expect(user.isHR, isFalse);
      expect(user.isAttendanceApplicable, isFalse);
      expect(user.canAccessAttendance, isFalse);
      expect(user.canAccessLeaves, isFalse);
      expect(user.canManageRoles, isTrue);
      expect(user.canManageSystem, isTrue);
    });

    test('HR user model correctly enables attendance, leaves, and approvals', () {
      final json = {
        'id': 2,
        'name': 'HR Manager',
        'email': 'hr@capeonn.test',
        'is_active': true,
        'is_attendance_applicable': true,
        'salary': 75000.50,
        'role': {
          'id': 3,
          'name': 'HR',
          'slug': 'hr',
          'level': 80,
        },
        'permissions': {
          'attendance.record': 'self',
          'attendance.view': 'all',
          'leave.apply': 'self',
          'leave.approve': 'all',
          'documents.verify': 'all',
          'holidays.manage': 'all',
        },
      };

      final user = AuthUser.fromJson(json);

      expect(user.isSuperAdmin, isFalse);
      expect(user.isHR, isTrue);
      expect(user.isAttendanceApplicable, isTrue);
      expect(user.salary, 75000.50);
      expect(user.canAccessAttendance, isTrue);
      expect(user.canAccessLeaves, isTrue);
      expect(user.canRecordAttendance, isTrue);
      expect(user.canApplyLeave, isTrue);
      expect(user.canApproveLeave, isTrue);
      expect(user.canVerifyDocuments, isTrue);
      expect(user.canManageHolidays, isTrue);
      expect(user.canManageRoles, isFalse);
      expect(user.canManageSystem, isFalse);
    });

    test('LeaveRequestItem parses approver and finalApprover fields', () {
      final json = {
        'id': 10,
        'user_id': 5,
        'user_name': 'Employee Jane',
        'leave_type_id': 1,
        'leave_type_name': 'Paid Leave',
        'leave_type_code': 'PL',
        'start_date': '2026-10-15',
        'end_date': '2026-10-16',
        'is_half_day': false,
        'days_count': 2.0,
        'reason': 'Vacation',
        'status': 'pending',
        'approver_id': 2,
        'approver_name': 'HR Manager',
        'final_approver': true,
        'created_at': '2026-10-01T12:00:00Z',
      };

      final leave = LeaveRequestItem.fromJson(json);

      expect(leave.id, 10);
      expect(leave.approverId, 2);
      expect(leave.approverName, 'HR Manager');
      expect(leave.finalApprover, isTrue);
    });

    test('AttendanceToday parses isApplicable status', () {
      final json = {
        'date': '2026-10-01',
        'is_clocked_in': false,
        'is_clocked_out': false,
        'is_applicable': false,
        'elapsed_seconds': 0,
        'office_locations': [],
      };

      final today = AttendanceToday.fromJson(json);

      expect(today.isApplicable, isFalse);
    });

    test('ApiException formats 403 forbidden responses gracefully', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/attendance/clock-in'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/attendance/clock-in'),
          statusCode: 403,
          data: {
            'success': false,
            'message': 'Attendance check-in is not applicable for your account',
            'errors': null,
          },
        ),
      );

      final apiEx = ApiException.fromDio(dioException);

      expect(apiEx.isForbidden, isTrue);
      expect(apiEx.displayMessage, 'Attendance check-in is not applicable for your account');

      final emptyForbidden = DioException(
        requestOptions: RequestOptions(path: '/api/v1/roles'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/roles'),
          statusCode: 403,
          data: {
            'success': false,
            'message': '',
          },
        ),
      );

      final apiEx2 = ApiException.fromDio(emptyForbidden);
      expect(apiEx2.displayMessage, "You don't have permission to perform this action.");
    });
  });
}
