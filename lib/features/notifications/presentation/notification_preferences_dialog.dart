import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/notification_controller.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

class NotificationPreferencesDialog extends ConsumerStatefulWidget {
  const NotificationPreferencesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const NotificationPreferencesDialog(),
    );
  }

  @override
  ConsumerState<NotificationPreferencesDialog> createState() =>
      _NotificationPreferencesDialogState();
}

class _NotificationPreferencesDialogState
    extends ConsumerState<NotificationPreferencesDialog> {
  bool _isSendingTest = false;

  Future<void> _sendTestPush() async {
    setState(() => _isSendingTest = true);
    try {
      final res = await ref.read(notificationRepositoryProvider).sendTestPush();
      ref.invalidate(notificationUnreadCountProvider);
      ref.invalidate(notificationsListProvider(false));
      if (!mounted) return;
      final msg = res['message'] as String? ?? 'Test push dispatched successfully';
      AppToast.success(context, msg);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _isSendingTest = false);
    }
  }

  void _updatePreference(
    NotificationPreferencesModel current,
    NotificationPreferencesModel Function(NotificationPreferencesModel) updater,
  ) {
    final updated = updater(current);
    ref.read(notificationPreferencesProvider.notifier).updatePreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Preferences',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customize alert delivery across push and in-app channels',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Content body
              Flexible(
                child: prefsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load preferences: $err',
                        style: const TextStyle(color: AppColors.rose),
                      ),
                    ),
                  ),
                  data: (prefs) => ListView(
                    shrinkWrap: true,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Push Notifications (FCM)',
                        subtitle: 'Receive alerts when the app is in background or closed',
                        value: prefs.pushEnabled,
                        onChanged: (val) => _updatePreference(
                          prefs,
                          (p) => p.copyWith(pushEnabled: val),
                        ),
                      ),
                      _buildSwitchTile(
                        icon: Icons.task_alt_rounded,
                        title: 'Task & Workflow Alerts',
                        subtitle: 'Assignments, handovers, reviews, and approval decisions',
                        value: prefs.taskAlerts,
                        onChanged: (val) => _updatePreference(
                          prefs,
                          (p) => p.copyWith(taskAlerts: val),
                        ),
                      ),
                      _buildSwitchTile(
                        icon: Icons.alarm_rounded,
                        title: 'Deadline & Overdue Alerts',
                        subtitle: 'Approaching project/task due dates and overdue warnings',
                        value: prefs.deadlineAlerts,
                        onChanged: (val) => _updatePreference(
                          prefs,
                          (p) => p.copyWith(deadlineAlerts: val),
                        ),
                      ),
                      _buildSwitchTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chat Messages & @Mentions',
                        subtitle: 'Direct messages, group updates, and threaded mentions',
                        value: prefs.chatAlerts,
                        onChanged: (val) => _updatePreference(
                          prefs,
                          (p) => p.copyWith(chatAlerts: val),
                        ),
                      ),
                      _buildSwitchTile(
                        icon: Icons.folder_special_outlined,
                        title: 'Project Updates',
                        subtitle: 'Team memberships, completion requests, and file uploads',
                        value: prefs.projectAlerts,
                        onChanged: (val) => _updatePreference(
                          prefs,
                          (p) => p.copyWith(projectAlerts: val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action buttons footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSendingTest ? null : _sendTestPush,
                    icon: _isSendingTest
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_isSendingTest ? 'Sending...' : 'Send Test Push'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 17,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
