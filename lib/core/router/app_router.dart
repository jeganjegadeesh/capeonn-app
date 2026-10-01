import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/change_password_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/home/presentation/dashboard_overview_page.dart';
import '../../features/layout/presentation/app_shell.dart';
import '../../features/organization/presentation/company_page.dart';
import '../../features/organization/presentation/departments_page.dart';
import '../../features/organization/presentation/designations_page.dart';
import '../../features/organization/presentation/hierarchy_page.dart';
import '../../features/employees/presentation/employees_page.dart';
import '../../features/employees/presentation/employee_detail_page.dart';
import '../../features/attendance/presentation/attendance_page.dart';
import '../../features/leaves/presentation/leaves_page.dart';
import '../../features/holidays/presentation/holidays_page.dart';
import '../../features/admin_system/presentation/roles_permissions_page.dart';
import '../../features/admin_system/presentation/system_settings_page.dart';
import '../../features/admin_system/presentation/audit_logs_page.dart';

const _publicRoutes = {'/login', '/forgot-password', '/reset-password'};

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect logic whenever the sign-in state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Password-reset links from email must survive the start-up check.
      if (location == '/reset-password') return null;

      final auth = ref.read(authControllerProvider);
      if (auth.isLoading || auth.hasError) {
        return location == '/splash' ? null : '/splash';
      }

      final signedIn = auth.value != null;
      if (!signedIn) return _publicRoutes.contains(location) ? null : '/login';

      final user = auth.value!;
      // Super Admin: Hide and block attendance/leaves screens
      if (user.isSuperAdmin && (location.startsWith('/attendance') || location.startsWith('/leaves'))) {
        return '/home';
      }
      // Non-Super Admin: Block roles, system settings, and audit logs
      if (!user.isSuperAdmin && (location.startsWith('/roles') || location.startsWith('/settings') || location.startsWith('/audit'))) {
        return '/home';
      }

      if (location == '/splash' || location == '/login' || location == '/forgot-password') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordPage(
          token: state.uri.queryParameters['token'],
          email: state.uri.queryParameters['email'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const DashboardOverviewPage()),
          GoRoute(path: '/attendance', builder: (_, _) => const AttendancePage()),
          GoRoute(path: '/leaves', builder: (_, _) => const LeavesPage()),
          GoRoute(path: '/holidays', builder: (_, _) => const HolidaysPage()),
          GoRoute(path: '/employees', builder: (_, _) => const EmployeesPage()),
          GoRoute(
            path: '/employees/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return EmployeeDetailPage(employeeId: id);
            },
          ),
          GoRoute(path: '/hierarchy', builder: (_, _) => const HierarchyPage()),
          GoRoute(path: '/departments', builder: (_, _) => const DepartmentsPage()),
          GoRoute(path: '/designations', builder: (_, _) => const DesignationsPage()),
          GoRoute(path: '/company', builder: (_, _) => const CompanyPage()),
          GoRoute(path: '/roles', builder: (_, _) => const RolesPermissionsPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SystemSettingsPage()),
          GoRoute(path: '/audit', builder: (_, _) => const AuditLogsPage()),
          GoRoute(path: '/change-password', builder: (_, _) => const ChangePasswordPage()),
        ],
      ),
    ],
  );
});
