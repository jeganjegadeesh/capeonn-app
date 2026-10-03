import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../organization/application/organization_controller.dart';

class SystemSettingsPage extends ConsumerStatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  ConsumerState<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends ConsumerState<SystemSettingsPage> {
  bool _autoAttendanceSummary = true;
  bool _enforceGeofencing = true;
  bool _requireTwoFactor = false;

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

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
                          'System Settings',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Global system configuration, policies, and operational controls (Super Admin Only).',
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
                        Icon(Icons.settings, size: 16, color: Color(0xFF6D28D9)),
                        SizedBox(width: 6),
                        Text(
                          'System Level',
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
                    'System Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Global system configuration and controls.',
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
                        Icon(Icons.settings, size: 14, color: Color(0xFF6D28D9)),
                        SizedBox(width: 4),
                        Text(
                          'System Level',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Theme & Appearance Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme & Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Choose between light, dark, or system preference for the Capeonn interface.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: const ThemeSegmentedSwitch(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Organization Overview Card
            companyAsync.when(
              data: (company) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Company Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Company Name', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(company.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Timezone', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(company.timezone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Policy & Feature Toggles
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Strict Geofence Enforcement'),
                    subtitle: const Text('Flag attendance check-ins recorded outside designated company geofence coordinates.'),
                    value: _enforceGeofencing,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _enforceGeofencing = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Automated Daily Absentee Marking'),
                    subtitle: const Text('Automatically mark employees without check-in as absent after cut-off time.'),
                    value: _autoAttendanceSummary,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _autoAttendanceSummary = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication for Admins'),
                    subtitle: const Text('Enforce additional verification step during login for high-privilege roles.'),
                    value: _requireTwoFactor,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _requireTwoFactor = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
