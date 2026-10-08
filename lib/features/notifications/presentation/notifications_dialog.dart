import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/notification_controller.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

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
  bool _unreadOnly = false;

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
        return Icons.alternate_email;
      case 'chat_message':
        return Icons.chat_bubble_outline;
      case 'task_assigned':
      case 'task_updated':
        return Icons.task_alt;
      case 'project_update':
        return Icons.folder_special;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'chat_mention':
        return AppColors.amber;
      case 'chat_message':
        return AppColors.primary;
      case 'task_assigned':
      case 'task_updated':
        return AppColors.emerald;
      case 'project_update':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _handleTapNotification(AppNotificationItem item) async {
    if (!item.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(item.id);
        ref.invalidate(notificationUnreadCountProvider);
        ref.invalidate(notificationsListProvider(_unreadOnly));
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    if (item.conversationId != null) {
      context.push('/chat/${item.conversationId}');
    } else if (item.projectId != null) {
      context.push('/projects/${item.projectId}');
    } else if (item.taskId != null) {
      context.push('/tasks');
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationUnreadCountProvider);
      ref.invalidate(notificationsListProvider(_unreadOnly));
      if (mounted) {
        AppToast.success(context, 'All notifications marked as read');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to mark all as read: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(notificationsListProvider(_unreadOnly));

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.notifications, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 440,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All', style: TextStyle(fontSize: 12)),
                    selected: !_unreadOnly,
                    onSelected: (val) => setState(() => _unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread Only', style: TextStyle(fontSize: 12)),
                    selected: _unreadOnly,
                    onSelected: (val) => setState(() => _unreadOnly = true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: listAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load notifications: $err', style: TextStyle(color: AppColors.rose, fontSize: 12)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(notificationsListProvider(_unreadOnly)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (data) {
                  final items = data.items;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _unreadOnly ? 'No unread notifications' : 'No notifications yet',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        dense: true,
                        tileColor: item.isRead ? null : AppColors.primary.withValues(alpha: 0.05),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _colorForType(item.type).withValues(alpha: 0.15),
                          child: Icon(_iconForType(item.type), size: 16, color: _colorForType(item.type)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(item.createdAt),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () => _handleTapNotification(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
