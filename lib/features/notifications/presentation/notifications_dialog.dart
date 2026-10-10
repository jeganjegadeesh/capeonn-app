import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../tasks/presentation/widgets/task_detail_dialog.dart';
import '../application/notification_controller.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';
import 'notification_preferences_dialog.dart';

class NotificationsDialog extends ConsumerStatefulWidget {
  const NotificationsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const NotificationsDialog(),
    );
  }

  @override
  ConsumerState<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends ConsumerState<NotificationsDialog> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'chat_mention':
        return Icons.alternate_email_rounded;
      case 'chat_message':
        return Icons.chat_bubble_outline_rounded;
      case 'task_assigned':
      case 'task_reassigned':
        return Icons.assignment_ind_rounded;
      case 'task_review':
        return Icons.rate_review_rounded;
      case 'task_changes_requested':
        return Icons.edit_note_rounded;
      case 'task_completed':
        return Icons.check_circle_rounded;
      case 'task_reopened':
        return Icons.restart_alt_rounded;
      case 'task_overdue':
      case 'project_overdue':
        return Icons.alarm_off_rounded;
      case 'task_due_soon':
      case 'project_deadline_approaching':
        return Icons.alarm_rounded;
      case 'task_comment':
        return Icons.comment_rounded;
      case 'project_lead_assigned':
      case 'project_member_added':
        return Icons.folder_shared_rounded;
      case 'project_file_uploaded':
        return Icons.upload_file_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'chat_mention':
        return AppColors.amber;
      case 'chat_message':
        return AppColors.primary;
      case 'task_assigned':
      case 'task_reassigned':
      case 'task_completed':
        return AppColors.emerald;
      case 'task_review':
        return const Color(0xFF6366F1); // Indigo
      case 'task_changes_requested':
        return Colors.orange;
      case 'task_reopened':
        return Colors.purple;
      case 'task_overdue':
      case 'project_overdue':
        return AppColors.rose;
      case 'task_due_soon':
      case 'project_deadline_approaching':
        return AppColors.amber;
      case 'project_file_uploaded':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _handleTapNotification(AppNotificationItem item) async {
    if (!item.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(item.id);
        ref.invalidate(notificationUnreadCountProvider);
        ref.invalidate(notificationsListProvider(false));
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (item.taskId != null) {
      showDialog(
        context: context,
        builder: (_) => TaskDetailDialog(taskId: item.taskId!),
      );
    } else if (item.conversationId != null) {
      GoRouter.of(context).push('/chat/${item.conversationId}');
    } else if (item.projectId != null) {
      GoRouter.of(context).push('/projects/${item.projectId}');
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationUnreadCountProvider);
      ref.invalidate(notificationsListProvider(false));
      if (mounted) {
        AppToast.success(context, 'All notifications marked as read');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e);
      }
    }
  }

  Future<void> _deleteNotification(AppNotificationItem item) async {
    try {
      await ref.read(notificationRepositoryProvider).deleteNotification(item.id);
      ref.invalidate(notificationUnreadCountProvider);
      ref.invalidate(notificationsListProvider(false));
      if (mounted) {
        AppToast.success(context, 'Notification removed');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e);
      }
    }
  }

  List<AppNotificationItem> _filterItems(List<AppNotificationItem> items) {
    switch (_selectedCategory) {
      case NotificationCategory.unread:
        return items.where((i) => !i.isRead).toList();
      case NotificationCategory.tasks:
        return items.where((i) => i.type.startsWith('task_')).toList();
      case NotificationCategory.projects:
        return items.where((i) => i.type.startsWith('project_')).toList();
      case NotificationCategory.chat:
        return items.where((i) => i.type.startsWith('chat_')).toList();
      case NotificationCategory.all:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsListProvider(false));

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.notifications_rounded,
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
                          'Notifications',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Task updates, project alerts & messaging',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notification Preferences',
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                      NotificationPreferencesDialog.show(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All', NotificationCategory.all),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Unread', NotificationCategory.unread),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Tasks', NotificationCategory.tasks),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Projects', NotificationCategory.projects),
                    const SizedBox(width: 6),
                    _buildCategoryChip('Chat', NotificationCategory.chat),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),

              // Body Notification Stream
              Expanded(
                child: notificationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load notifications: $err',
                        style: const TextStyle(color: AppColors.rose),
                      ),
                    ),
                  ),
                  data: (paginated) {
                    final filteredItems = _filterItems(paginated.items);

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedCategory == NotificationCategory.unread
                                    ? 'No unread notifications'
                                    : 'No notifications in this category',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "You're all caught up!",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final itemColor = _colorForType(item.type);

                        return Dismissible(
                          key: ValueKey('notif_${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppColors.rose.withValues(alpha: 0.15),
                            child: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
                          ),
                          onDismissed: (_) => _deleteNotification(item),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _iconForType(item.type),
                                color: itemColor,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  item.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(item.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _handleTapNotification(item),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 1),
              const SizedBox(height: 10),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark all as read'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, NotificationCategory category) {
    final isSelected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (val) {
        if (val) setState(() => _selectedCategory = category);
      },
    );
  }
}
