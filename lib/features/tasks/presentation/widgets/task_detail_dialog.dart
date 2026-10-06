import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/task_models.dart';
import '../../data/task_repository.dart';
import '../../application/tasks_providers.dart';
import 'task_status_dialog.dart';
import 'task_form_dialog.dart';
import 'manual_time_dialog.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../../projects/application/project_files_controller.dart';
import '../../../projects/data/project_files_repository.dart';
import '../../../chat/data/chat_repository.dart';


class TaskDetailDialog extends ConsumerStatefulWidget {
  const TaskDetailDialog({
    super.key,
    required this.taskId,
  });

  final int taskId;

  @override
  ConsumerState<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends ConsumerState<TaskDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(taskDetailProvider(widget.taskId));
    final activeTimer = ref.watch(activeTimerProvider);
    final currentUser = ref.watch(authControllerProvider).value;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: detailAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: AppColors.rose),
                const SizedBox(height: 12),
                Text('Failed to load task details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('$err', style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(taskDetailProvider(widget.taskId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (detail) {
            final task = detail.task;
            final isTimerRunningOnThisTask = activeTimer.isRunning && activeTimer.entry?.taskId == task.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (detail.project != null) ...[
                                  Text(
                                    detail.project!.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text('  /  ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                                Text(
                                  task.isSubtask ? 'Subtask #${task.id}' : 'Task #${task.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Discuss in Project Chat button
                      if (task.projectId > 0)
                        IconButton(
                          onPressed: () async {
                            try {
                              final conv = await ref
                                  .read(chatRepositoryProvider)
                                  .getProjectConversation(task.projectId);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                context.push('/chat/${conv.id}');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.error(context, 'Project chat not found');
                              }
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          tooltip: 'Discuss in Project Chat',
                          color: AppColors.primary,
                        ),
                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Top Info Bar (Status, Priority, Assignee, Deadlines)
                Container(
                  color: AppColors.surfaceHover,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Status button
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => TaskStatusDialog(task: task),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: task.statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: task.statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(task.statusIcon, size: 14, color: task.statusColor),
                              const SizedBox(width: 6),
                              Text(
                                task.statusDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: task.statusColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 14, color: task.statusColor),
                            ],
                          ),
                        ),
                      ),

                      // Priority Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: task.priorityColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: task.priorityColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              task.priorityDisplay,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: task.priorityColor),
                            ),
                          ],
                        ),
                      ),

                      // Assignee Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              task.assignedTo?.name ?? 'Unassigned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: task.assignedTo != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Due Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: task.isOverdue ? AppColors.rose.withValues(alpha: 0.5) : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 13, color: task.isOverdue ? AppColors.rose : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              task.deadlineDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                                color: task.isOverdue ? AppColors.rose : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Timer Bar on the Task
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isTimerRunningOnThisTask
                        ? AppColors.primaryContainer
                        : AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      // Hours Comparison (Estimated vs Actual)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Time: ',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                Text(
                                  '${task.actualHours.toStringAsFixed(1)}h actual',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (task.estimatedHours != null) ...[
                                  Text(
                                    '  /  ${task.estimatedHours}h est.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: task.timeVarianceColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.timeVarianceDisplay,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: task.timeVarianceColor,
                                      ),
                                    ),
                                  ),
                                ],
                                if (task.isCompleted && task.deadlineVariance != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: task.deadlineVarianceColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.deadlineVarianceDisplay,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: task.deadlineVarianceColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (task.estimatedHours != null && task.estimatedHours! > 0) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (task.actualHours / task.estimatedHours!).clamp(0.0, 1.0),
                                  backgroundColor: AppColors.surfaceHover,
                                  color: task.actualHours > task.estimatedHours!
                                      ? AppColors.rose
                                      : AppColors.primary,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Timer Action Buttons
                      if (isTimerRunningOnThisTask) ...[
                        // Running timer ticker
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (activeTimer.isPaused)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('PAUSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              Text(
                                activeTimer.formattedTime,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (activeTimer.isPaused)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ref.read(activeTimerProvider.notifier).resumeTimer(task.id);
                              ref.invalidate(taskDetailProvider(widget.taskId));
                            },
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Resume'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ref.read(activeTimerProvider.notifier).pauseTimer(task.id);
                              ref.invalidate(taskDetailProvider(widget.taskId));
                            },
                            icon: const Icon(Icons.pause, size: 14),
                            label: const Text('Pause'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceHover,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ref.read(activeTimerProvider.notifier).stopTimer(task.id);
                            ref.invalidate(taskDetailProvider(widget.taskId));
                          },
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('Stop Timer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rose,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ref.read(activeTimerProvider.notifier).startTimer(task.id);
                              ref.invalidate(taskDetailProvider(widget.taskId));
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.error(context, e);
                              }
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Start Timer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],

                      const SizedBox(width: 8),

                      // Manual Log Time button
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ManualTimeDialog(task: task),
                          );
                        },
                        icon: const Icon(Icons.add_alarm, size: 14),
                        label: const Text('Log Hours'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Text(
                      task.description!,
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                    ),
                  ),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.checklist, size: 16),
                          const SizedBox(width: 6),
                          Text('Subtasks (${detail.subtasks.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text('Time Logs (${detail.timeEntries.length})'),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Comments'),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 16),
                          SizedBox(width: 6),
                          Text('Attachments'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 16),
                          const SizedBox(width: 6),
                          Text('Activity (${detail.activities.length})'),
                        ],
                      ),
                    ),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Subtasks Tab
                      _buildSubtasksTab(context, detail, currentUser),

                      // 2. Time Logs Tab
                      _buildTimeLogsTab(context, detail),

                      // 3. Comments Tab (Phase 6 Placeholder)
                      _buildCommentsPlaceholderTab(context, detail),

                      // 4. Attachments Tab (Phase 6 Placeholder)
                      _buildAttachmentsPlaceholderTab(context, detail),

                      // 5. Activity History Tab
                      _buildActivityTab(detail),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubtasksTab(BuildContext context, TaskDetail detail, dynamic currentUser) {
    return Column(
      children: [
        // Subtask Header & Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Break this task into smaller steps:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TaskFormDialog(
                      projectId: detail.task.projectId,
                      parentTaskId: detail.task.id,
                      teamLead: detail.task.assignedTo,
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Add Subtask'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: detail.subtasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist, size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No subtasks yet', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Add subtasks to track granular checklist items', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: detail.subtasks.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sub = detail.subtasks[index];
                    final isDone = sub.status == TaskStatus.completed;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: Checkbox(
                        value: isDone,
                        activeColor: AppColors.emerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (checked) async {
                          try {
                            final newStatus = checked == true ? TaskStatus.completed : TaskStatus.inProgress;
                            await ref.read(taskRepositoryProvider).updateTaskStatus(sub.id, newStatus);
                            ref.invalidate(taskDetailProvider(widget.taskId));
                            ref.invalidate(projectTasksProvider(detail.task.projectId));
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(context, e);
                            }
                          }
                        },
                      ),
                      title: Text(
                        sub.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sub.assignedTo != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sub.assignedTo!.name,
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sub.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sub.statusDisplay,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub.statusColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimeLogsTab(BuildContext context, TaskDetail detail) {
    if (detail.timeEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_off_outlined, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('No time logged yet', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Start the live timer or log manual work duration above', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: detail.timeEntries.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = detail.timeEntries[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: entry.isManual ? AppColors.amberContainer : AppColors.primaryContainer,
            child: Icon(
              entry.isManual ? Icons.edit_calendar : Icons.timer,
              size: 16,
              color: entry.isManual ? AppColors.amber : AppColors.primary,
            ),
          ),
          title: Row(
            children: [
              Text(
                entry.user?.name ?? 'User #${entry.userId}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.isManual ? 'Manual Log' : 'Live Timer',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.description != null && entry.description!.isNotEmpty)
                Text(
                  entry.description!,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              Text(
                entry.startedAt != null ? entry.startedAt!.split('T').first : 'Recent',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.durationHours.toStringAsFixed(2)}h',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Time Log'),
                      content: const Text('Are you sure you want to remove this time tracking entry?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(taskRepositoryProvider).deleteTimeEntry(entry.id);
                    ref.invalidate(taskDetailProvider(widget.taskId));
                    ref.invalidate(projectTasksProvider(detail.task.projectId));
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.textMuted,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(TaskDetail detail) {
    if (detail.activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('No activity records found', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: detail.activities.length,
      itemBuilder: (context, index) {
        final act = detail.activities[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.description,
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      act.createdAt != null
                          ? act.createdAt!.replaceFirst('T', ' ').split('.').first
                          : '',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsPlaceholderTab(BuildContext context, TaskDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.forum_outlined, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Task Comments & Discussions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Collaborate with team members, mention colleagues (@username), and resolve task blockers directly in context.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Scheduled for Phase 6 Collaboration',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Mock comment box preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Icon(Icons.person, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Write a comment or feedback on this task...',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                    Icon(Icons.send_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsPlaceholderTab(BuildContext context, TaskDetail detail) {
    final filesAsync = ref.watch(projectFilesProvider(detail.task.projectId));

    return filesAsync.when(
      data: (allFiles) {
        final taskFiles = allFiles.where((f) => f.taskId == detail.task.id).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deliverables & Attachments (${taskFiles.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Add File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showTaskFileUploadDialog(context, detail),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (taskFiles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'No files attached to this task yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Upload test evidence, wireframes, PR links, or specifications.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: taskFiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final file = taskFiles[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2FE),
                          child: Icon(Icons.insert_drive_file, color: Color(0xFF0284C7), size: 20),
                        ),
                        title: Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${file.formattedSize} • Uploaded by ${file.uploaderName}', style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          tooltip: 'Download',
                          onPressed: () => AppToast.success(context, 'Downloading ${file.fileName}...'),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Failed to load files: $err', style: const TextStyle(color: AppColors.rose))),
    );
  }

  void _showTaskFileUploadDialog(BuildContext context, TaskDetail detail) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Attach Task File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File Name *',
                  hintText: 'e.g. test_results.pdf',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief note on this deliverable...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: isUploading
                  ? null
                  : () async {
                      final fname = nameController.text.trim();
                      if (fname.isEmpty) return;

                      setDialogState(() => isUploading = true);
                      try {
                        final repo = ref.read(projectFilesRepositoryProvider);
                        final dummyContent = utf8.encode('Task Deliverable: $fname\nTask: ${detail.task.title}');

                        await repo.uploadProjectFile(
                          detail.task.projectId,
                          fileBytes: dummyContent,
                          fileName: fname,
                          category: 'document',
                          taskId: detail.task.id,
                          description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                        );

                        ref.invalidate(projectFilesProvider(detail.task.projectId));
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          AppToast.success(context, 'File attached to task successfully');
                        }
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        if (context.mounted) {
                          AppToast.error(context, 'Failed to attach file: $e');
                        }
                      }
                    },
              child: Text(isUploading ? 'Uploading...' : 'Attach File'),
            ),
          ],
        ),
      ),
    );
  }
}
