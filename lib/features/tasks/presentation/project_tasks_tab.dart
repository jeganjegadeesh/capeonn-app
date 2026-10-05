import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/data/project_models.dart';
import '../data/task_models.dart';
import '../data/task_repository.dart';
import '../application/tasks_providers.dart';
import 'widgets/task_form_dialog.dart';
import 'widgets/task_status_dialog.dart';
import 'widgets/task_detail_dialog.dart';

class ProjectTasksTab extends ConsumerStatefulWidget {
  const ProjectTasksTab({
    super.key,
    required this.project,
    this.members = const [],
  });

  final ProjectItem project;
  final List<ProjectMemberItem> members;

  @override
  ConsumerState<ProjectTasksTab> createState() => _ProjectTasksTabState();
}

class _ProjectTasksTabState extends ConsumerState<ProjectTasksTab> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  bool _isKanbanView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    ref.read(projectTasksFilterProvider.notifier).setFilter(
      widget.project.id,
      ProjectTasksFilter(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        priority: _selectedPriority == 'all' ? null : _selectedPriority,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        rootOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(projectTasksProvider(widget.project.id));
    final activeTimer = ref.watch(activeTimerProvider);
    final user = ref.watch(authControllerProvider).value;

    final isProjectManager = widget.project.managerId != null && widget.project.managerId == user?.id;
    final isDeptManager = user?.isManager == true &&
        widget.project.departmentId != null &&
        user?.departmentId != null &&
        widget.project.departmentId == user?.departmentId;
    final isTeamLead = user?.isTeamLead == true && widget.project.teamLeadId == user?.id;

    final canManageTasks = (user?.isAdmin == true) ||
        (user?.canManageTasks == true && (isProjectManager || isDeptManager || isTeamLead));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Header Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilter(),
                    decoration: InputDecoration(
                      hintText: 'Search tasks by title or description...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilter();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Priority Dropdown Filter
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPriority,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                      DropdownMenuItem(value: TaskPriority.urgent, child: Text('Urgent')),
                      DropdownMenuItem(value: TaskPriority.high, child: Text('High')),
                      DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium')),
                      DropdownMenuItem(value: TaskPriority.low, child: Text('Low')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPriority = val);
                        _applyFilter();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // View Mode Toggle (List vs Kanban)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'List View',
                      icon: Icon(
                        Icons.view_list,
                        size: 20,
                        color: !_isKanbanView ? AppColors.primary : AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _isKanbanView = false),
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    IconButton(
                      tooltip: 'Kanban Board View',
                      icon: Icon(
                        Icons.view_column_outlined,
                        size: 20,
                        color: _isKanbanView ? AppColors.primary : AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _isKanbanView = true),
                    ),
                  ],
                ),
              ),

              if (canManageTasks && widget.project.acceptsWork) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => TaskFormDialog(
                        projectId: widget.project.id,
                        projectMembers: widget.members,
                        teamLead: widget.project.teamLeadId != null
                            ? TaskUserItem(
                                id: widget.project.teamLeadId!,
                                name: widget.project.teamLeadName ?? 'Team Lead',
                              )
                            : null,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusFilterChip('all', 'All Tasks'),
                const SizedBox(width: 8),
                _statusFilterChip(TaskStatus.review, 'Review Queue'),
                const SizedBox(width: 8),
                _statusFilterChip(TaskStatus.inProgress, 'In Progress'),
                const SizedBox(width: 8),
                _statusFilterChip(TaskStatus.assigned, 'Assigned'),
                const SizedBox(width: 8),
                _statusFilterChip(TaskStatus.backlog, 'Backlog'),
                const SizedBox(width: 8),
                _statusFilterChip(TaskStatus.changesRequired, 'Changes Req.'),
                const SizedBox(width: 8),
                _statusFilterChip(TaskStatus.completed, 'Completed'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tasks View (List or Kanban)
          tasksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 36, color: AppColors.rose),
                  const SizedBox(height: 8),
                  Text('Failed to load project tasks: $err', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(projectTasksProvider(widget.project.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.assignment_outlined, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Tasks Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          canManageTasks
                              ? 'Team leads and managers can create tasks, assign them to team members, set priorities and estimate hours.'
                              : 'Tasks assigned to this project will appear here once created by your Team Lead.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                        ),
                        if (canManageTasks && widget.project.acceptsWork) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => TaskFormDialog(
                                  projectId: widget.project.id,
                                  projectMembers: widget.members,
                                  teamLead: widget.project.teamLeadId != null
                                      ? TaskUserItem(
                                          id: widget.project.teamLeadId!,
                                          name: widget.project.teamLeadName ?? 'Team Lead',
                                        )
                                      : null,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_task),
                            label: const Text('Create First Task'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (_isKanbanView) {
                return _buildKanbanBoard(tasks, activeTimer, canManageTasks);
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final isRunning = activeTimer.isRunning && activeTimer.entry?.taskId == task.id;

                  return _TaskCard(
                    task: task,
                    project: widget.project,
                    members: widget.members,
                    isRunningTimer: isRunning,
                    canManage: canManageTasks,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard(List<TaskItem> allTasks, ActiveTimerState activeTimer, bool canManage) {
    const statuses = [
      TaskStatus.backlog,
      TaskStatus.assigned,
      TaskStatus.inProgress,
      TaskStatus.review,
      TaskStatus.changesRequired,
      TaskStatus.completed,
    ];

    return SizedBox(
      height: 640,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, idx) {
          final status = statuses[idx];
          final colTasks = allTasks.where((t) => t.status == status).toList();
          final statusColor = TaskStatus.color(status);

          return Container(
            width: 290,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.2))),
                  ),
                  child: Row(
                    children: [
                      Icon(TaskStatus.icon(status), size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        status == TaskStatus.review ? 'Review Queue' : TaskStatus.label(status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${colTasks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tasks in this column
                Expanded(
                  child: colTasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 28, color: AppColors.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 6),
                                Text(
                                  'No tasks',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(10),
                          itemCount: colTasks.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, cIdx) {
                            final task = colTasks[cIdx];
                            final isRunning = activeTimer.isRunning && activeTimer.entry?.taskId == task.id;
                            return _KanbanTaskCard(
                              task: task,
                              project: widget.project,
                              members: widget.members,
                              isRunningTimer: isRunning,
                              canManage: canManage,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    final color = status == 'all' ? AppColors.primary : TaskStatus.color(status);

    return InkWell(
      onTap: () {
        setState(() => _selectedStatus = status);
        _applyFilter();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _KanbanTaskCard extends ConsumerWidget {
  const _KanbanTaskCard({
    required this.task,
    required this.project,
    required this.members,
    required this.isRunningTimer,
    required this.canManage,
  });

  final TaskItem task;
  final ProjectItem project;
  final List<ProjectMemberItem> members;
  final bool isRunningTimer;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRunningTimer ? AppColors.primary : AppColors.border,
          width: isRunningTimer ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => TaskDetailDialog(taskId: task.id),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Priority & Quick Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priorityDisplay,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: task.priorityColor,
                        ),
                      ),
                    ),
                    if (task.subtasksCount > 0) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.checklist, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        '${task.subtasksCount}',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => TaskStatusDialog(task: task),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.swap_horiz, size: 16, color: task.statusColor),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Due date & Overdue / Variance Badges
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (task.isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Overdue (${task.daysRemaining?.abs() ?? 0}d)',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.rose),
                        ),
                      )
                    else if (task.isDueToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Due Today',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      )
                    else if (task.isDueSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Due ${task.daysRemaining}d',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                    if (task.isCompleted && task.deadlineVariance != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: task.deadlineVarianceColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          task.deadlineVarianceDisplay,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: task.deadlineVarianceColor),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom row: Assignee & Hours
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        task.assignedTo?.name.isNotEmpty == true ? task.assignedTo!.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        task.assignedTo?.name ?? 'Unassigned',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${task.actualHours.toStringAsFixed(1)}h',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    required this.task,
    required this.project,
    required this.members,
    required this.isRunningTimer,
    required this.canManage,
  });

  final TaskItem task;
  final ProjectItem project;
  final List<ProjectMemberItem> members;
  final bool isRunningTimer;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunningTimer ? AppColors.primary : AppColors.border,
          width: isRunningTimer ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => TaskDetailDialog(taskId: task.id),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status badge, Priority badge, Timer quick action, Menu
                Row(
                  children: [
                    // Status Badge
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => TaskStatusDialog(task: task),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: task.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: task.statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(task.statusIcon, size: 12, color: task.statusColor),
                            const SizedBox(width: 4),
                            Text(
                              task.statusDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: task.statusColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down, size: 12, color: task.statusColor),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Priority Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.priorityDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: task.priorityColor,
                        ),
                      ),
                    ),

                    if (task.subtasksCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist, size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${task.subtasksCount} subtasks',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Timer button
                    if (isRunningTimer)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(activeTimerProvider.notifier).stopTimer(task.id);
                          ref.invalidate(projectTasksProvider(project.id));
                        },
                        icon: const Icon(Icons.stop, size: 14),
                        label: const Text('Stop Timer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (project.acceptsWork && !task.isCompleted)
                      IconButton(
                        tooltip: 'Start Live Timer',
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        color: AppColors.primary,
                        onPressed: () async {
                          try {
                            await ref.read(activeTimerProvider.notifier).startTimer(task.id);
                            ref.invalidate(projectTasksProvider(project.id));
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(context, e);
                            }
                          }
                        },
                      ),

                    // More Menu
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                      onSelected: (val) async {
                        if (val == 'details') {
                          showDialog(
                            context: context,
                            builder: (_) => TaskDetailDialog(taskId: task.id),
                          );
                        } else if (val == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => TaskFormDialog(
                              projectId: project.id,
                              taskToEdit: task,
                              projectMembers: members,
                              teamLead: project.teamLeadId != null
                                  ? TaskUserItem(id: project.teamLeadId!, name: project.teamLeadName ?? '')
                                  : null,
                            ),
                          );
                        } else if (val == 'subtask') {
                          showDialog(
                            context: context,
                            builder: (_) => TaskFormDialog(
                              projectId: project.id,
                              parentTaskId: task.id,
                              teamLead: task.assignedTo,
                            ),
                          );
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Task?'),
                              content: Text('Are you sure you want to delete task "${task.title}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(taskRepositoryProvider).deleteTask(task.id);
                            ref.invalidate(projectTasksProvider(project.id));
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'details', child: Text('View Details')),
                        if (project.acceptsWork) ...[
                          const PopupMenuItem(value: 'subtask', child: Text('Add Subtask')),
                          if (canManage) ...[
                            const PopupMenuItem(value: 'edit', child: Text('Edit Task')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete Task', style: TextStyle(color: Colors.red))),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom Row: Assignee, Due Date & Badges, Hours Progress
                Row(
                  children: [
                    // Assignee
                    Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedTo?.name ?? 'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: task.assignedTo != null ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Deadline text
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: task.isOverdue ? AppColors.rose : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.deadlineDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                        color: task.isOverdue ? AppColors.rose : AppColors.textSecondary,
                      ),
                    ),

                    // Due Badges
                    if (task.isOverdue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Overdue',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.rose),
                        ),
                      ),
                    ] else if (task.isDueToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Due Today',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ),
                    ] else if (task.isDueSoon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Due in ${task.daysRemaining}d',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
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
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: task.deadlineVarianceColor),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Time Variance & Hours
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${task.actualHours.toStringAsFixed(1)}h',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        if (task.estimatedHours != null) ...[
                          Text(' / ${task.estimatedHours}h', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: task.timeVarianceColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.timeVarianceDisplay,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: task.timeVarianceColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
