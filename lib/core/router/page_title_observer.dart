import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Observer that updates the browser tab / system application title
/// dynamically on route changes across Web and Desktop platforms.
class PageTitleObserver extends NavigatorObserver {
  PageTitleObserver();

  static String getTitleForLocation(String location) {
    final clean = location.split('?').first;
    if (clean == '/home' || clean == '/') return 'Capeonn — Dashboard';
    if (clean == '/projects') return 'Capeonn — Projects';
    if (clean.startsWith('/projects/')) return 'Capeonn — Project Workspace';
    if (clean == '/tasks') return 'Capeonn — My Tasks';
    if (clean == '/reports') return 'Capeonn — Reports & Analytics';
    if (clean == '/chat') return 'Capeonn — Internal Chat';
    if (clean.startsWith('/chat/')) return 'Capeonn — Chat Room';
    if (clean == '/attendance') return 'Capeonn — Attendance';
    if (clean == '/leaves') return 'Capeonn — Leave Management';
    if (clean == '/holidays') return 'Capeonn — Holiday Calendar';
    if (clean == '/employees') return 'Capeonn — Employees Directory';
    if (clean.startsWith('/employees/')) return 'Capeonn — Employee Profile';
    if (clean == '/hierarchy') return 'Capeonn — Organization Hierarchy';
    if (clean == '/departments') return 'Capeonn — Departments';
    if (clean == '/designations') return 'Capeonn — Designations';
    if (clean == '/company') return 'Capeonn — Company Profile';
    if (clean == '/roles') return 'Capeonn — Roles & Permissions';
    if (clean == '/settings') return 'Capeonn — System Settings';
    if (clean == '/audit') return 'Capeonn — Audit Logs';
    if (clean == '/change-password') return 'Capeonn — Change Password';
    if (clean == '/login') return 'Capeonn — Sign In';
    if (clean == '/forgot-password') return 'Capeonn — Forgot Password';
    if (clean == '/reset-password') return 'Capeonn — Reset Password';
    return 'Capeonn';
  }

  static void updateTitle(String location) {
    final title = getTitleForLocation(location);
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(label: title),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _syncTitle(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _syncTitle(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _syncTitle(previousRoute);
  }

  void _syncTitle(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      updateTitle(name);
    }
  }
}
