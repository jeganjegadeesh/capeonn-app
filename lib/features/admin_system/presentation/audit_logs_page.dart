import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

class AuditLogsPage extends ConsumerWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final mockLogs = [
      (
        'Role Separation Migration',
        'Phase 3 Super Admin & HR role separation applied. Cleaned up admin leave/attendance balances.',
        'System Seeder',
        'Just now',
        Icons.security,
        const Color(0xFF6D28D9),
      ),
      (
        'HR Account Seeded',
        'Second operational HR account (hr@capeonn.test) provisioned with HR level 80 permissions.',
        'Super Admin',
        '10 mins ago',
        Icons.person_add,
        const Color(0xFF0F766E),
      ),
      (
        'Database Backup Completed',
        'Automatic SQL backup captured prior to Phase 3 updates in storage/database/backups.',
        'System Daemon',
        '1 hour ago',
        Icons.backup,
        AppColors.primary,
      ),
      (
        'Office Locations Verified',
        'Main HQ geofencing radius confirmed at 500 meters.',
        'Admin',
        '3 hours ago',
        Icons.location_on,
        AppColors.emerald,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audit & Security Logs',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track system events, administrator modifications, and security actions.',
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
                        Icon(Icons.history_edu, size: 16, color: Color(0xFF6D28D9)),
                        SizedBox(width: 6),
                        Text(
                          'Audit Trail',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit & Security Logs',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track system events, administrator modifications, and security actions.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_edu, size: 14, color: Color(0xFF6D28D9)),
                        SizedBox(width: 4),
                        Text(
                          'Audit Trail',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockLogs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final (action, details, actor, time, icon, color) = mockLogs[idx];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      action,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(time, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(details, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('Actor: $actor', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
