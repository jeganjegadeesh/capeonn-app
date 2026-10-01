import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_user.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final location = GoRouterState.of(context).matchedLocation;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    final navItems = _buildNavItems(user);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              user: user,
              currentLocation: location,
              items: navItems,
              onSignOut: () => ref.read(authControllerProvider.notifier).logout(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile / Tablet Layout
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'CAPEONN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _titleForRoute(location),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Change Password',
            icon: const Icon(Icons.lock_reset, size: 22),
            onPressed: () => context.push('/change-password'),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, size: 22),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: _Sidebar(
            user: user,
            currentLocation: location,
            items: navItems,
            isDrawer: true,
            onSignOut: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: _buildBottomBar(context, location, navItems),
    );
  }

  List<_NavItem> _buildNavItems(AuthUser user) {
    final list = <_NavItem>[
      const _NavItem(title: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, route: '/home'),
    ];

    // Attendance & Leaves are strictly hidden for Super Admin
    if (user.canAccessAttendance && (user.canViewAttendance || user.canRecordAttendance)) {
      list.add(const _NavItem(title: 'Attendance', icon: Icons.access_time_outlined, activeIcon: Icons.access_time_filled, route: '/attendance'));
    }

    if (user.canAccessLeaves && (user.canViewLeaves || user.canApplyLeave)) {
      list.add(const _NavItem(title: 'Leaves', icon: Icons.event_note_outlined, activeIcon: Icons.event_note, route: '/leaves'));
    }

    if (user.canViewHolidays) {
      list.add(const _NavItem(title: 'Holidays', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, route: '/holidays'));
    }

    if (user.canViewEmployees) {
      list.add(const _NavItem(title: 'Employees', icon: Icons.people_outline, activeIcon: Icons.people, route: '/employees'));
      list.add(const _NavItem(title: 'Hierarchy', icon: Icons.account_tree_outlined, activeIcon: Icons.account_tree, route: '/hierarchy'));
    }

    if (user.canViewOrganization) {
      list.add(const _NavItem(title: 'Departments', icon: Icons.apartment_outlined, activeIcon: Icons.apartment, route: '/departments'));
      list.add(const _NavItem(title: 'Designations', icon: Icons.badge_outlined, activeIcon: Icons.badge, route: '/designations'));
      list.add(const _NavItem(title: 'Company', icon: Icons.business_outlined, activeIcon: Icons.business, route: '/company'));
    }

    // Role-based menus: Super Admin sees Roles, Settings and Audit; HR does not.
    if (user.isSuperAdmin) {
      list.add(const _NavItem(title: 'Roles & Permissions', icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, route: '/roles'));
      list.add(const _NavItem(title: 'System Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, route: '/settings'));
      list.add(const _NavItem(title: 'Audit Logs', icon: Icons.history_edu_outlined, activeIcon: Icons.history_edu, route: '/audit'));
    }

    return list;
  }

  String _titleForRoute(String route) {
    if (route.startsWith('/attendance')) return 'Attendance';
    if (route.startsWith('/leaves')) return 'Leaves';
    if (route.startsWith('/holidays')) return 'Holiday Calendar';
    if (route.startsWith('/employees')) return 'Employees';
    if (route.startsWith('/hierarchy')) return 'Org Hierarchy';
    if (route.startsWith('/departments')) return 'Departments';
    if (route.startsWith('/designations')) return 'Designations';
    if (route.startsWith('/company')) return 'Company Profile';
    if (route.startsWith('/roles')) return 'Roles & Permissions';
    if (route.startsWith('/settings')) return 'System Settings';
    if (route.startsWith('/audit')) return 'Audit Logs';
    if (route.startsWith('/change-password')) return 'Change Password';
    return 'Dashboard';
  }

  Widget? _buildBottomBar(BuildContext context, String currentRoute, List<_NavItem> items) {
    if (items.length > 5) return null; // Use drawer if too many items

    int currentIndex = items.indexWhere((it) => currentRoute == it.route || currentRoute.startsWith('${it.route}/'));
    if (currentIndex < 0) currentIndex = 0;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (idx) => context.go(items[idx].route),
      destinations: items.map((it) => NavigationDestination(
        icon: Icon(it.icon),
        selectedIcon: Icon(it.activeIcon),
        label: it.title,
      )).toList(),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.user,
    required this.currentLocation,
    required this.items,
    required this.onSignOut,
    this.isDrawer = false,
  });

  final AuthUser user;
  final String currentLocation;
  final List<_NavItem> items;
  final VoidCallback onSignOut;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final (roleBg, roleFg) = AppColors.rolePillColors(user.roleSlug);

    return Container(
      width: isDrawer ? null : 260,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAPEONN',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        user.companyName ?? 'Enterprise Workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'MAIN NAVIGATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                for (final item in items) ...[
                  _SidebarTile(
                    item: item,
                    isActive: currentLocation == item.route || currentLocation.startsWith('${item.route}/'),
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      context.go(item.route);
                    },
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // User Card & Sign Out
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: roleBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user.roleName.isNotEmpty ? user.roleName : user.roleSlug.toUpperCase(),
                                style: TextStyle(
                                  color: roleFg,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            if (isDrawer) Navigator.pop(context);
                            context.push('/change-password');
                          },
                          child: const Text('Password', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Sign out',
                        icon: const Icon(Icons.logout, size: 18, color: AppColors.rose),
                        onPressed: onSignOut,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
