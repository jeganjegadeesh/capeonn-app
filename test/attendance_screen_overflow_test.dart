import 'package:capeonn_app/core/theme/app_theme.dart';
import 'package:capeonn_app/features/attendance/application/attendance_controller.dart';
import 'package:capeonn_app/features/attendance/data/attendance_models.dart';
import 'package:capeonn_app/features/attendance/presentation/attendance_page.dart';
import 'package:capeonn_app/features/auth/application/auth_controller.dart';
import 'package:capeonn_app/provider/auth/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendance Screen Viewport Overflow Tests', () {
    late AuthUser adminUser;
    late AuthUser employeeUser;
    late AttendanceToday adminToday;
    late AttendanceToday employeeToday;
    late AttendanceSummary adminSummary;
    late AttendanceDailyStatusResult dailyStatus;
    late List<AttendanceRecord> sampleRecords;
    late List<AttendanceRegularization> sampleRegs;

    setUp(() {
      adminUser = AuthUser.fromJson({
        'id': 1,
        'name': 'Super Administrator',
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
      });

      employeeUser = AuthUser.fromJson({
        'id': 4,
        'name': 'Eli Employee',
        'email': 'employee@capeonn.test',
        'is_active': true,
        'is_attendance_applicable': true,
        'role': {
          'id': 4,
          'name': 'Employee',
          'slug': 'employee',
          'level': 10,
        },
        'permissions': {
          'attendance.record': 'self',
          'attendance.view': 'self',
        },
      });

      adminToday = const AttendanceToday(
        date: '2026-10-16',
        isClockedIn: false,
        isClockedOut: false,
        isApplicable: false,
        elapsedSeconds: 0,
        officeLocations: [
          OfficeLocation(
            id: 1,
            name: 'Capeonn HQ - Indiranagar Campus',
            address: '100 Feet Rd, Indiranagar, Bengaluru',
            latitude: 12.9716,
            longitude: 77.5946,
            radiusMeters: 500,
          ),
        ],
      );

      employeeToday = const AttendanceToday(
        date: '2026-10-16',
        isClockedIn: true,
        isClockedOut: false,
        isApplicable: true,
        elapsedSeconds: 3600,
        officeLocations: [
          OfficeLocation(
            id: 1,
            name: 'Capeonn HQ',
            address: 'Bengaluru',
            latitude: 12.9716,
            longitude: 77.5946,
            radiusMeters: 500,
          ),
        ],
      );

      adminSummary = const AttendanceSummary(
        year: 2026,
        month: 10,
        daysPresent: 12,
        daysLate: 2,
        daysHalfDay: 1,
        totalHours: 94.5,
        totalRecords: 15,
        eligibleUsersCount: 8,
        todayClockedInCount: 6,
        todayClockedOutCount: 1,
        todayLateCount: 1,
        todayFlaggedCount: 1,
        todayAbsentCount: 2,
        isOrganization: true,
      );

      dailyStatus = const AttendanceDailyStatusResult(
        date: '2026-10-16',
        totalUsers: 8,
        presentCount: 6,
        lateCount: 1,
        clockedInCount: 6,
        absentCount: 2,
        flaggedCount: 1,
        users: [
          AttendanceDailyUserStatus(
            userId: 4,
            userName: 'Eli Employee with Long Name',
            employeeCode: 'CAP-0004',
            departmentName: 'Product Engineering',
            designationName: 'Senior Software Engineer',
            date: '2026-10-16',
            status: 'present',
            isClockedIn: true,
            isClockedOut: false,
            clockInAt: '2026-10-16T09:15:00Z',
            clockInLocationName: 'Indiranagar Campus HQ',
            isFlagged: false,
            totalMinutes: 180,
            totalHoursFormatted: '3h 00m',
          ),
        ],
      );

      sampleRecords = const [
        AttendanceRecord(
          id: 1,
          userId: 4,
          userName: 'Eli Employee with Long Name',
          employeeCode: 'CAP-0004',
          departmentName: 'Product Engineering',
          date: '2026-10-16',
          clockInAt: '2026-10-16T09:15:00Z',
          clockOutAt: '2026-10-16T18:00:00Z',
          clockInLocationName: 'Bangalore Office Campus',
          isFlagged: true,
          flaggedReason: 'Out-of-office location punch detected',
          geofenceStatus: 'outside',
          status: 'present',
          totalMinutes: 525,
          totalHoursFormatted: '8h 45m',
        ),
      ];

      sampleRegs = const [
        AttendanceRegularization(
          id: 1,
          userId: 4,
          userName: 'Eli Employee with Long Name',
          employeeCode: 'CAP-0004',
          date: '2026-10-15',
          requestedClockIn: '2026-10-15 09:00:00',
          requestedClockOut: '2026-10-15 18:00:00',
          reason: 'Biometric device failed during morning entry',
          status: 'pending',
          createdAt: '2026-10-15T10:00:00Z',
        ),
      ];
    });

    testWidgets('AttendancePage renders without overflow on 360x640 mobile viewport for admin', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _MockAuthController(adminUser)),
            attendanceTodayProvider.overrideWith(() => _MockTodayNotifier(adminToday)),
            attendanceSummaryProvider((null, null)).overrideWith((ref) => adminSummary),
            attendanceDailyStatusProvider(('2026-10-16', null)).overrideWith((ref) => dailyStatus),
            allAttendanceRecordsProvider((date: '2026-10-16', departmentId: null, userId: null, status: null, isFlagged: null)).overrideWith((ref) => sampleRecords),
            regularizationsProvider.overrideWith((ref) => sampleRegs),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AttendancePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hasOverflow = errors.any((e) => e.toString().contains('overflowed'));
      for (final e in errors) {
        if (e.toString().contains('overflowed')) {
          // ignore: avoid_print
          print('Overflow error detected: ${e.exceptionAsString()}');
        }
      }
      expect(hasOverflow, isFalse, reason: 'RenderFlex overflow occurred on 360x640 mobile viewport');
    });

    testWidgets('AttendancePage renders without overflow on 320x568 compact viewport for admin', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _MockAuthController(adminUser)),
            attendanceTodayProvider.overrideWith(() => _MockTodayNotifier(adminToday)),
            attendanceSummaryProvider((null, null)).overrideWith((ref) => adminSummary),
            attendanceDailyStatusProvider(('2026-10-16', null)).overrideWith((ref) => dailyStatus),
            allAttendanceRecordsProvider((date: '2026-10-16', departmentId: null, userId: null, status: null, isFlagged: null)).overrideWith((ref) => sampleRecords),
            regularizationsProvider.overrideWith((ref) => sampleRegs),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AttendancePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hasOverflow = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflow, isFalse, reason: 'RenderFlex overflow occurred on 320x568 compact viewport');
    });

    testWidgets('AttendancePage renders without overflow on 360x640 mobile viewport for employee', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _MockAuthController(employeeUser)),
            attendanceTodayProvider.overrideWith(() => _MockTodayNotifier(employeeToday)),
            attendanceSummaryProvider((null, null)).overrideWith((ref) => const AttendanceSummary(
                  year: 2026,
                  month: 10,
                  daysPresent: 10,
                  daysLate: 1,
                  daysHalfDay: 0,
                  totalHours: 80.0,
                  totalRecords: 11,
                  isOrganization: false,
                )),
            myAttendanceRecordsProvider((null, null)).overrideWith((ref) => sampleRecords),
            regularizationsProvider.overrideWith((ref) => sampleRegs),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AttendancePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final hasOverflow = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflow, isFalse, reason: 'RenderFlex overflow occurred on 360x640 mobile viewport');
    });

    testWidgets('AttendancePage switching to Punch Logs and tabs has no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _MockAuthController(adminUser)),
            attendanceTodayProvider.overrideWith(() => _MockTodayNotifier(adminToday)),
            attendanceSummaryProvider((null, null)).overrideWith((ref) => adminSummary),
            attendanceDailyStatusProvider(('2026-10-16', null)).overrideWith((ref) => dailyStatus),
            allAttendanceRecordsProvider((date: '2026-10-16', departmentId: null, userId: null, status: null, isFlagged: null)).overrideWith((ref) => sampleRecords),
            regularizationsProvider.overrideWith((ref) => sampleRegs),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AttendancePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Punch Logs
      final punchLogsFinder = find.text('Punch Logs');
      expect(punchLogsFinder, findsOneWidget);
      await tester.ensureVisible(punchLogsFinder);
      await tester.tap(punchLogsFinder);
      await tester.pumpAndSettle();

      // Switch tab to Regularization Requests
      final regTabFinder = find.text('Regularization Requests');
      expect(regTabFinder, findsOneWidget);
      await tester.ensureVisible(regTabFinder);
      await tester.tap(regTabFinder);
      await tester.pumpAndSettle();

      // Switch tab to Office Locations
      final locTabFinder = find.text('Office Locations');
      expect(locTabFinder, findsOneWidget);
      await tester.ensureVisible(locTabFinder);
      await tester.tap(locTabFinder);
      await tester.pumpAndSettle();

      final hasOverflow = errors.any((e) => e.toString().contains('overflowed'));
      expect(hasOverflow, isFalse, reason: 'RenderFlex overflow occurred when navigating tabs or views');
    });
  });
}

class _MockAuthController extends AuthController {
  _MockAuthController(this._user);
  final AuthUser? _user;

  @override
  Future<AuthUser?> build() async => _user;
}

class _MockTodayNotifier extends AttendanceTodayNotifier {
  _MockTodayNotifier(this._today);
  final AttendanceToday? _today;

  @override
  Future<AttendanceToday?> build() async => _today;
}
