import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../employees/application/employee_controller.dart';

class RolesPermissionsPage extends ConsumerWidget {
  const RolesPermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(assignableRolesProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Roles & Permissions Management',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System roles, hierarchy levels, and access boundaries (Super Admin Only).',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, size: 16, color: Color(0xFF6D28D9)),
                      SizedBox(width: 6),
                      Text(
                        'Super Admin Only',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            rolesAsync.when(
              data: (roles) {
                if (roles.isEmpty) {
                  return const Center(child: Text('No roles defined.'));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final role = roles[idx];
                    final (roleBg, roleFg) = AppColors.rolePillColors(role.slug);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: roleBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.admin_panel_settings, color: roleFg, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        role.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(4)),
                                        child: Text(
                                          'Level ${role.level}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleFg),
                                        ),
                                      ),
                                      if (role.isSystem) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('SYSTEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    role.description ?? 'Role description and operational scopes.',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Role Identifier: ${role.slug}',
                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Text('Error loading roles: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
