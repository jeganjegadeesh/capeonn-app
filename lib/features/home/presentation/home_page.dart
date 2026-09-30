import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';

/// Placeholder landing screen: proves login works and shows what the server says this user may do.
/// Real dashboards arrive with the later phases.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink(); // signing out; the router is about to redirect

    final theme = Theme.of(context);
    final permissions = user.permissions.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capeonn'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: theme.textTheme.titleLarge),
                                Text(user.roleName, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(Icons.email_outlined, 'Email', user.email),
                      _InfoRow(Icons.badge_outlined, 'Employee code', user.employeeCode),
                      _InfoRow(Icons.business_outlined, 'Company', user.companyName),
                      _InfoRow(Icons.apartment_outlined, 'Department', user.departmentName),
                      _InfoRow(Icons.work_outline, 'Designation', user.designationName),
                      _InfoRow(Icons.supervisor_account_outlined, 'Reports to', user.reportsToName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your access', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('permission · scope', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in permissions) Chip(label: Text('${entry.key} · ${entry.value}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/change-password'),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Change password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value == null || value!.isEmpty ? '—' : value!)),
        ],
      ),
    );
  }
}
