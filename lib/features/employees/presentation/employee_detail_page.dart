import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/employee_controller.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';
import 'employee_form_dialog.dart';

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final int employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final employeeAsync = ref.watch(employeeDetailProvider(employeeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.rose),
              const SizedBox(height: 12),
              Text(
                err is ApiException ? err.displayMessage : 'Failed to load employee details',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(employeeDetailProvider(employeeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (emp) {
          final (roleBg, roleFg) = AppColors.rolePillColors(emp.roleSlug);
          final (statusBg, statusFg) = AppColors.statusPillColors(emp.isActive);
          final isMobile = MediaQuery.sizeOf(context).width < 768;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: roleBg,
                                        child: Text(
                                          emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: roleFg,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              emp.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              emp.email,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (user?.canManageEmployees == true)
                                        IconButton(
                                          tooltip: 'Edit Employee',
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          onPressed: () async {
                                            await showDialog(
                                              context: context,
                                              builder: (ctx) => EmployeeFormDialog(employee: emp),
                                            );
                                            ref.invalidate(employeeDetailProvider(employeeId));
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (emp.employeeCode != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text(
                                            emp.employeeCode!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: roleBg,
                                    child: Text(
                                      emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: roleFg,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              emp.name,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
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
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          emp.email,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: roleBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                emp.roleName,
                                                style: TextStyle(
                                                  color: roleFg,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (emp.employeeCode != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Text(
                                                  emp.employeeCode!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (user?.canManageEmployees == true) ...[
                                    IconButton(
                                      tooltip: 'Edit Employee',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (ctx) => EmployeeFormDialog(employee: emp),
                                        );
                                        ref.invalidate(employeeDetailProvider(employeeId));
                                      },
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Organization & Job Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Position & Organization',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow('Department', emp.departmentName),
                            const SizedBox(height: 12),
                            _InfoRow('Designation', emp.designationName),
                            const SizedBox(height: 12),
                            _InfoRow('Reports To (Supervisor)', emp.reportsToName),
                            const SizedBox(height: 12),
                            _InfoRow('Date Joined', emp.joinedOn ?? '—'),
                            const SizedBox(height: 12),
                            _InfoRow('Last Active / Login', emp.lastLoginAt ?? 'Never logged in'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Details',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow('Official Email', emp.email),
                            const SizedBox(height: 12),
                            _InfoRow('Contact Phone', emp.phone ?? 'Not provided'),
                          ],
                        ),
                      ),
                    ),

                    if (user?.canManageEmployees == true) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.rose,
                              side: const BorderSide(color: AppColors.rose),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete Employee'),
                            onPressed: () => _confirmDelete(context, ref, emp),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${emp.name}? '
            'Their account will be terminated.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(employeeRepositoryProvider).deleteEmployee(emp.id);
                ref.invalidate(employeesListProvider);
                if (context.mounted) {
                  context.pop();
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 550;
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
