import 'package:flutter_test/flutter_test.dart';
import 'package:capeonn_app/features/attendance/data/attendance_models.dart';
import 'package:capeonn_app/features/leaves/data/leave_models.dart';
import 'package:capeonn_app/features/holidays/data/holiday_models.dart';
import 'package:capeonn_app/features/employees/data/employee_details_models.dart';

void main() {
  group('Phase 3 - Attendance Models', () {
    test('OfficeLocation parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Headquarters',
        'address': 'Level 4, Tech Park, Chennai',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'radius_meters': 300,
      };

      final loc = OfficeLocation.fromJson(json);
      expect(loc.id, 1);
      expect(loc.name, 'Headquarters');
      expect(loc.address, 'Level 4, Tech Park, Chennai');
      expect(loc.latitude, 13.0827);
      expect(loc.longitude, 80.2707);
      expect(loc.radiusMeters, 300);
    });

    test('AttendanceRecord parses correctly with status and location', () {
      final json = {
        'id': 101,
        'user_id': 5,
        'user_name': 'Esha Employee',
        'employee_code': 'CAP-0005',
        'department_name': 'Engineering',
        'date': '2026-03-30',
        'clock_in_at': '2026-03-30T09:00:00Z',
        'clock_out_at': '2026-03-30T17:30:00Z',
        'clock_in_location_name': 'Headquarters',
        'is_flagged': false,
        'flagged_reason': null,
        'geofence_status': 'inside',
        'status': 'present',
        'total_minutes': 510,
        'total_hours_formatted': '8h 30m',
        'notes': 'Normal day',
      };

      final rec = AttendanceRecord.fromJson(json);
      expect(rec.id, 101);
      expect(rec.userId, 5);
      expect(rec.userName, 'Esha Employee');
      expect(rec.employeeCode, 'CAP-0005');
      expect(rec.departmentName, 'Engineering');
      expect(rec.clockInLocationName, 'Headquarters');
      expect(rec.isFlagged, isFalse);
      expect(rec.geofenceStatus, 'inside');
      expect(rec.status, 'present');
      expect(rec.totalMinutes, 510);
      expect(rec.totalHoursFormatted, '8h 30m');
      expect(rec.notes, 'Normal day');
    });

    test('AttendanceToday parses active state and locations', () {
      final json = {
        'date': '2026-03-30',
        'is_clocked_in': true,
        'is_clocked_out': false,
        'elapsed_seconds': 14400,
        'attendance': {
          'id': 102,
          'user_id': 5,
          'date': '2026-03-30',
          'clock_in_at': '2026-03-30T09:00:00Z',
          'geofence_status': 'inside',
          'status': 'present',
        },
        'office_locations': [
          {
            'id': 1,
            'name': 'HQ',
            'latitude': 13.0,
            'longitude': 80.0,
            'radius_meters': 200,
          }
        ],
      };

      final today = AttendanceToday.fromJson(json);
      expect(today.date, '2026-03-30');
      expect(today.isClockedIn, isTrue);
      expect(today.isClockedOut, isFalse);
      expect(today.elapsedSeconds, 14400);
      expect(today.attendance?.id, 102);
      expect(today.officeLocations.length, 1);
      expect(today.officeLocations.first.name, 'HQ');
    });

    test('AttendanceSummary parses aggregated totals', () {
      final json = {
        'year': 2026,
        'month': 3,
        'days_present': 22,
        'days_late': 1,
        'days_half_day': 0,
        'total_hours': 180.5,
        'total_records': 23,
      };

      final sum = AttendanceSummary.fromJson(json);
      expect(sum.year, 2026);
      expect(sum.month, 3);
      expect(sum.daysPresent, 22);
      expect(sum.daysLate, 1);
      expect(sum.daysHalfDay, 0);
      expect(sum.totalHours, 180.5);
      expect(sum.totalRecords, 23);
    });

    test('AttendanceRegularization parses with user and approver details', () {
      final json = {
        'id': 201,
        'attendance_id': 101,
        'user_id': 5,
        'user_name': 'Esha Employee',
        'date': '2026-03-29',
        'requested_clock_in': '09:00',
        'requested_clock_out': '18:00',
        'reason': 'Forgot badge / card',
        'status': 'approved',
        'rejection_reason': null,
        'created_at': '2026-03-29T18:30:00Z',
      };

      final item = AttendanceRegularization.fromJson(json);
      expect(item.id, 201);
      expect(item.attendanceId, 101);
      expect(item.userName, 'Esha Employee');
      expect(item.requestedClockIn, '09:00');
      expect(item.requestedClockOut, '18:00');
      expect(item.status, 'approved');
      expect(item.rejectionReason, isNull);
    });
  });

  group('Phase 3 - Leave Models', () {
    test('LeaveType parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Casual Leave',
        'code': 'CL',
        'description': 'Casual leave allocation',
        'annual_days': 12.0,
        'is_paid': true,
      };

      final lt = LeaveType.fromJson(json);
      expect(lt.id, 1);
      expect(lt.name, 'Casual Leave');
      expect(lt.code, 'CL');
      expect(lt.annualDays, 12.0);
      expect(lt.isPaid, isTrue);
    });

    test('LeaveBalance parses with utilization percentages', () {
      final json = {
        'id': 10,
        'leave_type_id': 1,
        'name': 'Casual Leave',
        'code': 'CL',
        'is_paid': true,
        'year': 2026,
        'total_days': 12.0,
        'used_days': 3.0,
        'pending_days': 1.0,
        'remaining_days': 8.0,
      };

      final bal = LeaveBalance.fromJson(json);
      expect(bal.id, 10);
      expect(bal.name, 'Casual Leave');
      expect(bal.totalDays, 12.0);
      expect(bal.usedDays, 3.0);
      expect(bal.remainingDays, 8.0);
    });

    test('LeaveRequestItem parses half day and approval status', () {
      final json = {
        'id': 50,
        'user_id': 5,
        'user_name': 'Esha Employee',
        'employee_code': 'CAP-0005',
        'department_name': 'Engineering',
        'leave_type_id': 1,
        'leave_type_name': 'Casual Leave',
        'leave_type_code': 'CL',
        'start_date': '2026-04-10',
        'end_date': '2026-04-10',
        'is_half_day': true,
        'half_day_type': 'first_half',
        'days_count': 0.5,
        'reason': 'Doctor appointment',
        'status': 'pending',
        'created_at': '2026-04-01T10:00:00Z',
      };

      final req = LeaveRequestItem.fromJson(json);
      expect(req.id, 50);
      expect(req.userName, 'Esha Employee');
      expect(req.leaveTypeName, 'Casual Leave');
      expect(req.isHalfDay, isTrue);
      expect(req.halfDayType, 'first_half');
      expect(req.daysCount, 0.5);
      expect(req.status, 'pending');
    });
  });

  group('Phase 3 - Holiday Models', () {
    test('HolidayItem parses categories and past indicator', () {
      final json = {
        'id': 1,
        'name': 'New Year',
        'date': '2026-01-01',
        'day_of_week': 'Thursday',
        'holiday_type': 'national',
        'description': 'Celebration of New Year',
        'is_optional': false,
        'is_past': true,
      };

      final h = HolidayItem.fromJson(json);
      expect(h.id, 1);
      expect(h.name, 'New Year');
      expect(h.dayOfWeek, 'Thursday');
      expect(h.holidayType, 'national');
      expect(h.isOptional, isFalse);
      expect(h.isPast, isTrue);
    });
  });

  group('Phase 3 - Employee Extended Details Models', () {
    test('EmployeeDocumentItem formats file size and parses metadata', () {
      final json = {
        'id': 12,
        'user_id': 5,
        'title': 'Identity Passport',
        'document_type': 'id_proof',
        'file_path': 'documents/5/passport.pdf',
        'file_name': 'passport.pdf',
        'file_size': 2097152, // 2 MB
        'mime_type': 'application/pdf',
        'created_at': '2026-01-15T12:00:00Z',
      };

      final doc = EmployeeDocumentItem.fromJson(json);
      expect(doc.id, 12);
      expect(doc.title, 'Identity Passport');
      expect(doc.documentType, 'id_proof');
      expect(doc.fileSizeFormatted, '2.0 MB');
      expect(doc.mimeType, 'application/pdf');
    });

    test('EmployeeHistoryItem parses milestone event and date', () {
      final json = {
        'id': 7,
        'user_id': 5,
        'event_type': 'promotion',
        'title': 'Promoted to Senior Engineer',
        'description': 'Exceptional performance in Q4',
        'effective_date': '2026-03-01',
        'created_at': '2026-03-01T09:00:00Z',
      };

      final item = EmployeeHistoryItem.fromJson(json);
      expect(item.id, 7);
      expect(item.eventType, 'promotion');
      expect(item.title, 'Promoted to Senior Engineer');
      expect(item.effectiveDate, '2026-03-01');
    });
  });
}
