import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../organization/application/organization_controller.dart';
import '../application/employee_controller.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';
import 'employee_form_dialog.dart';

class EmployeesPage extends ConsumerWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final employeesAsync = ref.watch(employeesListProvider);
    final filter = ref.watch(employeesFilterProvider);
    final departmentsAsync = ref.watch(departmentsListProvider);
    final rolesAsync = ref.watch(assignableRolesProvider);

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Employees',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (user?.canManageEmployees == true)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Add Employee', style: TextStyle(fontSize: 13)),
                              onPressed: () => _openEmployeeDialog(context, ref, null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Directory of team members, reporting relationships & roles',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employee Directory',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Directory of team members, reporting relationships & roles',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (user?.canManageEmployees == true)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add Employee'),
                          onPressed: () => _openEmployeeDialog(context, ref, null),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Search & Filter Bar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.search, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search by name, email, or employee code...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  ref.read(employeesFilterProvider.notifier).setFilter(
                                        filter.copyWith(search: val.trim(), page: 1),
                                      );
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Department filter
                            departmentsAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (depts) => SizedBox(
                                width: isMobile ? double.infinity : 180,
                                child: DropdownButtonFormField<int?>(
                                  initialValue: filter.departmentId,
                                  isDense: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('All Departments')),
                                    for (final d in depts)
                                      DropdownMenuItem(value: d.id, child: Text(d.name)),
                                  ],
                                  onChanged: (val) {
                                    ref.read(employeesFilterProvider.notifier).setFilter(
                                          filter.copyWith(departmentId: () => val, page: 1),
                                        );
                                  },
                                ),
                              ),
                            ),

                            // Role filter
                            rolesAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (roles) => SizedBox(
                                width: isMobile ? double.infinity : 160,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: filter.role,
                                  isDense: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('All Roles')),
                                    for (final r in roles)
                                      DropdownMenuItem(value: r.slug, child: Text(r.name)),
                                  ],
                                  onChanged: (val) {
                                    ref.read(employeesFilterProvider.notifier).setFilter(
                                          filter.copyWith(role: () => val, page: 1),
                                        );
                                  },
                                ),
                              ),
                            ),

                            // Active status filter
                            SegmentedButton<bool?>(
                              segments: const [
                                ButtonSegment(value: null, label: Text('All')),
                                ButtonSegment(value: true, label: Text('Active')),
                                ButtonSegment(value: false, label: Text('Inactive')),
                              ],
                              selected: {filter.isActive},
                              onSelectionChanged: (set) {
                                ref.read(employeesFilterProvider.notifier).setFilter(
                                      filter.copyWith(isActive: () => set.first, page: 1),
                                    );
                              },
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                            ),

                            if (filter.search.isNotEmpty ||
                                filter.departmentId != null ||
                                filter.role != null ||
                                filter.isActive != null)
                              TextButton.icon(
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Reset Filters'),
                                onPressed: () {
                                  ref.read(employeesFilterProvider.notifier).setFilter(
                                        const EmployeesFilter(),
                                      );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Employee List
                employeesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.rose),
                          const SizedBox(height: 10),
                          Text(err is ApiException ? err.displayMessage : 'Failed to load employees'),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(employeesListProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (pageData) {
                    if (pageData.items.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No employees found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adjusting your search filters or add a new team member.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pageData.items.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final emp = pageData.items[idx];
                              final (roleBg, roleFg) = AppColors.rolePillColors(emp.roleSlug);
                              final (statusBg, statusFg) = AppColors.statusPillColors(emp.isActive);

                              if (isMobile) {
                                return InkWell(
                                  onTap: () => context.push('/employees/${emp.id}'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: roleBg,
                                              child: Text(
                                                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  color: roleFg,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    emp.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    emp.email,
                                                    style: TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                emp.isActive ? 'Active' : 'Inactive',
                                                style: TextStyle(
                                                  color: statusFg,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: roleBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                emp.roleName,
                                                style: TextStyle(
                                                  color: roleFg,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (emp.employeeCode != null && emp.employeeCode!.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.borderSubtle,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Text(
                                                  emp.employeeCode!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            if (emp.designationName.isNotEmpty || emp.departmentName.isNotEmpty)
                                              Text(
                                                [
                                                  if (emp.designationName.isNotEmpty) emp.designationName,
                                                  if (emp.departmentName.isNotEmpty) emp.departmentName,
                                                ].join(' • '),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                        if (user?.canManageEmployees == true) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                                onPressed: () => _openEmployeeDialog(context, ref, emp),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  foregroundColor: AppColors.rose,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                icon: const Icon(Icons.delete_outline, size: 16),
                                                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                                                onPressed: () => _confirmDelete(context, ref, emp),
                                              ),
                                              const Spacer(),
                                              Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                                            ],
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return InkWell(
                                onTap: () => context.push('/employees/${emp.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: roleBg,
                                        child: Text(
                                          emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: roleFg,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  emp.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (emp.employeeCode != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.borderSubtle,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppColors.border),
                                                    ),
                                                    child: Text(
                                                      emp.employeeCode!,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              emp.email,
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              emp.designationName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              emp.departmentName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: roleBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          emp.roleName,
                                          style: TextStyle(
                                            color: roleFg,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          emp.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: statusFg,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (user?.canManageEmployees == true) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'Edit Details',
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          onPressed: () => _openEmployeeDialog(context, ref, emp),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete Employee',
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.rose),
                                          onPressed: () => _confirmDelete(context, ref, emp),
                                        ),
                                      ],
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Pagination Footer
                        const SizedBox(height: 16),
                        if (isMobile)
                          Column(
                            children: [
                              Text(
                                'Showing ${(pageData.currentPage - 1) * pageData.perPage + 1} - '
                                '${((pageData.currentPage - 1) * pageData.perPage + pageData.items.length)} '
                                'of ${pageData.total} employees',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.chevron_left, size: 18),
                                    label: const Text('Prev'),
                                    onPressed: pageData.hasPrevPage
                                        ? () {
                                            ref.read(employeesFilterProvider.notifier).setFilter(
                                                  filter.copyWith(page: pageData.currentPage - 1),
                                                );
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${pageData.currentPage} / ${pageData.lastPage}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.chevron_right, size: 18),
                                    label: const Text('Next'),
                                    onPressed: pageData.hasNextPage
                                        ? () {
                                            ref.read(employeesFilterProvider.notifier).setFilter(
                                                  filter.copyWith(page: pageData.currentPage + 1),
                                                );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${(pageData.currentPage - 1) * pageData.perPage + 1} - '
                                '${((pageData.currentPage - 1) * pageData.perPage + pageData.items.length)} '
                                'of ${pageData.total} employees',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.chevron_left, size: 18),
                                    label: const Text('Previous'),
                                    onPressed: pageData.hasPrevPage
                                        ? () {
                                            ref.read(employeesFilterProvider.notifier).setFilter(
                                                  filter.copyWith(page: pageData.currentPage - 1),
                                                );
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${pageData.currentPage} / ${pageData.lastPage}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.chevron_right, size: 18),
                                    label: const Text('Next'),
                                    onPressed: pageData.hasNextPage
                                        ? () {
                                            ref.read(employeesFilterProvider.notifier).setFilter(
                                                  filter.copyWith(page: pageData.currentPage + 1),
                                                );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEmployeeDialog(BuildContext context, WidgetRef ref, Employee? employee) {
    showDialog(
      context: context,
      builder: (ctx) => EmployeeFormDialog(employee: employee),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${emp.name} (${emp.email})? '
            'Their sessions will be terminated and account soft deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(employeeRepositoryProvider).deleteEmployee(emp.id);
                ref.invalidate(employeesListProvider);
                ref.invalidate(potentialSupervisorsProvider);
                ref.invalidate(hierarchyListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Employee "${emp.name}" deleted')),
                  );
                }
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.displayMessage),
                      backgroundColor: AppColors.rose,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
