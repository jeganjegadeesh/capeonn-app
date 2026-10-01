import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../organization/application/organization_controller.dart';
import '../../employees/application/employee_controller.dart';

class DashboardOverviewPage extends ConsumerWidget {
  const DashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();

    final companyAsync = user.canViewOrganization ? ref.watch(companyProvider) : null;
    final departmentsAsync = user.canViewOrganization ? ref.watch(departmentsListProvider) : null;
    final designationsAsync = user.canViewOrganization ? ref.watch(designationsListProvider) : null;
    final employeesAsync = user.canViewEmployees ? ref.watch(employeesListProvider) : null;

    final (roleBg, roleFg) = AppColors.rolePillColors(user.roleSlug);
    final permissions = user.permissions.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Banner
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 24 : 32,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 14 : 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Welcome, ${user.name}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: roleBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.roleName.isNotEmpty ? user.roleName : user.roleSlug.toUpperCase(),
                                    style: TextStyle(
                                      color: roleFg,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.companyName ?? 'Capeonn Workspace'} · ${user.departmentName ?? 'General'} · ${user.designationName ?? 'Team'}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Metrics Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _MetricCard(
                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                          title: 'Employees',
                          icon: Icons.people_alt_outlined,
                          iconColor: AppColors.primary,
                          valueText: employeesAsync?.when(
                                data: (p) => '${p.total}',
                                loading: () => '…',
                                error: (_, _) => '—',
                              ) ??
                              companyAsync?.when(
                                data: (c) => '${c.employeesCount ?? 0}',
                                loading: () => '…',
                                error: (_, _) => '—',
                              ) ??
                              '1',
                          subtitle: 'Active team members',
                          onTap: user.canViewEmployees ? () => context.go('/employees') : null,
                        ),
                        _MetricCard(
                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                          title: 'Departments',
                          icon: Icons.apartment_outlined,
                          iconColor: AppColors.secondary,
                          valueText: departmentsAsync?.when(
                                data: (l) => '${l.length}',
                                loading: () => '…',
                                error: (_, _) => '—',
                              ) ??
                              companyAsync?.when(
                                data: (c) => '${c.departmentsCount ?? 0}',
                                loading: () => '…',
                                error: (_, _) => '—',
                              ) ??
                              '—',
                          subtitle: 'Functional divisions',
                          onTap: user.canViewOrganization ? () => context.go('/departments') : null,
                        ),
                        _MetricCard(
                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                          title: 'Designations',
                          icon: Icons.badge_outlined,
                          iconColor: AppColors.emerald,
                          valueText: designationsAsync?.when(
                                data: (l) => '${l.length}',
                                loading: () => '…',
                                error: (_, _) => '—',
                              ) ??
                              '—',
                          subtitle: 'Defined company roles',
                          onTap: user.canViewOrganization ? () => context.go('/designations') : null,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Quick Navigation Shortcuts
                const Text(
                  'Quick Management Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (user.isSuperAdmin) ...[
                      _ActionShortcut(
                        icon: Icons.admin_panel_settings,
                        label: 'Roles & Perms',
                        description: 'Manage system roles & grants',
                        onTap: () => context.go('/roles'),
                      ),
                      _ActionShortcut(
                        icon: Icons.settings,
                        label: 'System Settings',
                        description: 'Global controls & policies',
                        onTap: () => context.go('/settings'),
                      ),
                      _ActionShortcut(
                        icon: Icons.history_edu,
                        label: 'Audit Logs',
                        description: 'Security & system history',
                        onTap: () => context.go('/audit'),
                      ),
                    ],
                    if (user.canAccessAttendance)
                      _ActionShortcut(
                        icon: Icons.access_time,
                        label: 'Attendance',
                        description: 'Check in / track presence',
                        onTap: () => context.go('/attendance'),
                      ),
                    if (user.canAccessLeaves)
                      _ActionShortcut(
                        icon: Icons.event_note,
                        label: user.isHR ? 'Leave Approvals' : 'Leaves',
                        description: user.isHR ? 'Review employee leave queue' : 'Apply & track time off',
                        onTap: () => context.go('/leaves'),
                      ),
                    if (user.canViewHolidays)
                      _ActionShortcut(
                        icon: Icons.calendar_today,
                        label: 'Holiday Schedule',
                        description: 'Company & public holidays',
                        onTap: () => context.go('/holidays'),
                      ),
                    if (user.canViewEmployees) ...[
                      _ActionShortcut(
                        icon: Icons.people,
                        label: 'Directory',
                        description: 'View & search employees',
                        onTap: () => context.go('/employees'),
                      ),
                      _ActionShortcut(
                        icon: Icons.account_tree,
                        label: 'Org Chart',
                        description: 'Manager → TL → Staff chain',
                        onTap: () => context.go('/hierarchy'),
                      ),
                    ],
                    if (user.canViewOrganization) ...[
                      _ActionShortcut(
                        icon: Icons.apartment,
                        label: 'Departments',
                        description: 'Divisions & team heads',
                        onTap: () => context.go('/departments'),
                      ),
                      _ActionShortcut(
                        icon: Icons.business,
                        label: 'Company Profile',
                        description: 'Settings, timezone & info',
                        onTap: () => context.go('/company'),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // User Profile & Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Profile & Reporting Chain',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _DetailGrid(
                          items: [
                            ('Employee Code', user.employeeCode ?? '—'),
                            ('Email Address', user.email),
                            ('Contact Phone', user.phone ?? '—'),
                            ('Company', user.companyName ?? '—'),
                            ('Department', user.departmentName ?? '—'),
                            ('Designation', user.designationName ?? '—'),
                            ('Reporting Manager', user.reportsToName ?? 'Top-level / None'),
                            ('System Role', user.roleName.isNotEmpty ? user.roleName : user.roleSlug),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Permissions & Role Access
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Assigned Permissions & Scopes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${permissions.length} Grants',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enforced automatically by Capeonn API based on your current role level.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in permissions)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.valueText,
    required this.subtitle,
    this.onTap,
  });

  final double width;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String valueText;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
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

class _ActionShortcut extends StatelessWidget {
  const _ActionShortcut({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
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

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth < 600 ? constraints.maxWidth : (constraints.maxWidth - 24) / 2;
        final isVeryNarrow = constraints.maxWidth < 420;

        return Wrap(
          spacing: 24,
          runSpacing: 14,
          children: items.map((it) {
            return SizedBox(
              width: colWidth,
              child: isVeryNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          it.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            it.$1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            it.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          }).toList(),
        );
      },
    );
  }
}
