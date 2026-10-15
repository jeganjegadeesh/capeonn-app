import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/features/attendance/data/attendance_models.dart';

void main() {
  group('Admin Attendance Models & Features', () {
    test('AttendanceDailyStatusResult parses roster of all clock-in eligible users', () {
      final json = {
        'date': '2026-10-15',
        'total_users': 5,
        'present_count': 4,
        'late_count': 1,
        'clocked_in_count': 4,
        'absent_count': 1,
        'flagged_count': 1,
        'users': [
          {
            'user_id': 4,
            'user_name': 'Eli Employee',
            'email': 'employee1@capeonn.test',
            'avatar_url': 'http://localhost/api/v1/users/4/avatar',
            'avatar_path': 'avatars/avatar_4.png',
            'employee_code': 'CAP-0004',
            'department_name': 'Engineering',
            'designation_name': 'Software Engineer',
            'date': '2026-10-15',
            'attendance_id': 13,
            'status': 'late',
            'is_clocked_in': true,
            'is_clocked_out': false,
            'clock_in_at': '2026-10-15T09:48:00+00:00',
            'clock_out_at': null,
            'clock_in_location_name': 'Indiranagar Metro (Remote)',
            'is_flagged': true,
            'flagged_reason': 'Clocked in outside geofence (2100m from Capeonn HQ)',
            'geofence_status': 'outside',
            'total_minutes': 0,
            'total_hours_formatted': '0h 00m',
          },
          {
            'user_id': 5,
            'user_name': 'Esha Employee',
            'email': 'employee2@capeonn.test',
            'avatar_url': null,
            'avatar_path': null,
            'employee_code': 'CAP-0005',
            'department_name': 'Engineering',
            'designation_name': 'Software Engineer',
            'date': '2026-10-15',
            'attendance_id': null,
            'status': 'absent',
            'is_clocked_in': false,
            'is_clocked_out': false,
            'clock_in_at': null,
            'clock_out_at': null,
            'clock_in_location_name': null,
            'is_flagged': false,
            'flagged_reason': null,
            'geofence_status': 'unknown',
            'total_minutes': 0,
            'total_hours_formatted': '0h 00m',
          },
        ],
      };

      final result = AttendanceDailyStatusResult.fromJson(json);
      expect(result.date, '2026-10-15');
      expect(result.totalUsers, 5);
      expect(result.presentCount, 4);
      expect(result.lateCount, 1);
      expect(result.absentCount, 1);
      expect(result.flaggedCount, 1);
      expect(result.users.length, 2);

      final eli = result.users[0];
      expect(eli.userId, 4);
      expect(eli.userName, 'Eli Employee');
      expect(eli.avatarUrl, 'http://localhost/api/v1/users/4/avatar');
      expect(eli.isClockedIn, isTrue);
      expect(eli.isFlagged, isTrue);
      expect(eli.flaggedReason, contains('2100m'));

      final esha = result.users[1];
      expect(esha.userId, 5);
      expect(esha.userName, 'Esha Employee');
      expect(esha.status, 'absent');
      expect(esha.isClockedIn, isFalse);
    });

    test('AttendanceSummary parses organization metrics for administrators', () {
      final json = {
        'year': 2026,
        'month': 10,
        'days_present': 10,
        'days_late': 3,
        'days_half_day': 1,
        'total_hours': 82.9,
        'total_records': 14,
        'eligible_users_count': 5,
        'today_clocked_in_count': 4,
        'today_clocked_out_count': 0,
        'today_late_count': 1,
        'today_flagged_count': 1,
        'today_absent_count': 1,
        'is_organization': true,
      };

      final summary = AttendanceSummary.fromJson(json);
      expect(summary.isOrganization, isTrue);
      expect(summary.eligibleUsersCount, 5);
      expect(summary.todayClockedInCount, 4);
      expect(summary.todayLateCount, 1);
      expect(summary.todayAbsentCount, 1);
      expect(summary.totalRecords, 14);
      expect(summary.totalHours, 82.9);
    });

    test('AttendanceRecord parses avatar URL and path', () {
      final json = {
        'id': 11,
        'user_id': 2,
        'user_name': 'Meera Manager',
        'avatar_url': 'http://localhost/api/v1/users/2/avatar',
        'avatar_path': 'avatars/avatar_2.png',
        'employee_code': 'CAP-0002',
        'department_name': 'Engineering',
        'date': '2026-10-15',
        'clock_in_at': '2026-10-15T09:12:00+00:00',
        'clock_out_at': null,
        'is_flagged': false,
        'geofence_status': 'inside',
        'status': 'present',
        'total_minutes': 0,
        'total_hours_formatted': '0h 00m',
      };

      final record = AttendanceRecord.fromJson(json);
      expect(record.avatarUrl, 'http://localhost/api/v1/users/2/avatar');
      expect(record.avatarPath, 'avatars/avatar_2.png');
      expect(record.userName, 'Meera Manager');
      expect(record.status, 'present');
    });
  });
}
