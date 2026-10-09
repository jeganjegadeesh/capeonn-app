import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../data/task_models.dart';
import '../application/tasks_providers.dart';
import '../../auth/application/auth_controller.dart';
import 'widgets/task_status_dialog.dart';
import 'widgets/task_detail_dialog.dart';
import 'widgets/manual_time_dialog.dart';

class MyTasksPage extends ConsumerStatefulWidget {
  const MyTasksPage({super.key});

  @override
  ConsumerState<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends ConsumerState<MyTasksPage> {
  String _currentView = 'my_tasks';
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  bool _onlyOverdue = false;

  void _applyFilter() {
    ref.read(myTasksFilterProvider.notifier).setFilter(MyTasksFilter(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      priority: _selectedPriority == 'all' ? null : _selectedPriority,
      isOverdue: _onlyOverdue ? true : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(myTasksProvider);
    final activeTimer = ref.watch(activeTimerProvider);
    final currentUser = ref.watch(authControllerProvider).value;
    final canReview = currentUser?.isTeamLead == true ||
        currentUser?.isManager == true ||
        currentUser?.isAdmin == true;
    final reviewQueueAsync = canReview ? ref.watch(reviewQueueProvider) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentView == 'review_queue' ? 'Task Review Queue' : 'My Tasks & Time Tracking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentView == 'review_queue'
                          ? 'Review work submitted by project members, approve tasks, or request revisions.'
                          : 'Track your assigned work, record active timers, and meet project milestones.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Refresh tasks',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    if (_currentView == 'review_queue') {
                      ref.invalidate(reviewQueueProvider);
                    } else {
                      ref.invalidate(myTasksProvider);
                      ref.read(activeTimerProvider.notifier).checkActiveTimer();
                    }
                  },
                ),
              ],
            ),

            if (canReview) ...[
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  const ButtonSegment(
                    value: 'my_tasks',
                    label: Text('My Tasks'),
                    icon: Icon(Icons.assignment_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 'review_queue',
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Review Queue'),
                        reviewQueueAsync!.maybeWhen(
                          data: (q) => q.isNotEmpty
                              ? Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${q.length}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    icon: const Icon(Icons.rate_review_outlined, size: 16),
                  ),
                ],
                selected: {_currentView},
                onSelectionChanged: (set) {
                  setState(() => _currentView = set.first);
                },
              ),
            ],

            const SizedBox(height: 20),

            if (_currentView == 'review_queue' && canReview) ...[
              _buildReviewQueue(context, reviewQueueAsync!),
            ] else ...[
              // Active Timer Hero Card (if a timer is running)
              if (activeTimer.isRunning && activeTimer.entry != null) ...[
                _ActiveTimerHeroCard(entry: activeTimer.entry!, timerState: activeTimer),
                const SizedBox(height: 20),
              ],

              // KPIs Summary Row
              tasksAsync.when(
                data: (tasks) => _buildSummaryKpis(tasks),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

            // Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', 'All Tasks'),
                        const SizedBox(width: 8),
                        _filterChip(TaskStatus.review, 'Review Queue'),
                        const SizedBox(width: 8),
                        _filterChip(TaskStatus.inProgress, 'In Progress'),
                        const SizedBox(width: 8),
                        _filterChip(TaskStatus.assigned, 'Assigned'),
                        const SizedBox(width: 8),
                        _filterChip(TaskStatus.changesRequired, 'Changes Req.'),
                        const SizedBox(width: 8),
                        _filterChip(TaskStatus.completed, 'Completed'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Secondary filters: Priority & Overdue
                  Row(
                    children: [
                      // Priority Filter
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                              DropdownMenuItem(value: TaskPriority.urgent, child: Text('Urgent Only')),
                              DropdownMenuItem(value: TaskPriority.high, child: Text('High Priority')),
                              DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium Priority')),
                              DropdownMenuItem(value: TaskPriority.low, child: Text('Low Priority')),
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

                      const SizedBox(width: 12),

                      // Overdue Switch Chip
                      FilterChip(
                        selected: _onlyOverdue,
                        label: Text(
                          'Overdue Only',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _onlyOverdue ? FontWeight.bold : FontWeight.normal,
                            color: _onlyOverdue ? AppColors.rose : AppColors.textSecondary,
                          ),
                        ),
                        selectedColor: AppColors.roseContainer,
                        backgroundColor: AppColors.surfaceHover,
                        side: BorderSide(
                          color: _onlyOverdue ? AppColors.rose : AppColors.border,
                        ),
                        onSelected: (val) {
                          setState(() => _onlyOverdue = val);
                          _applyFilter();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tasks List
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
                    Text('Failed to load tasks: $err', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(myTasksProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 30),
                      padding: const EdgeInsets.all(32),
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.task_alt, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _onlyOverdue ? 'No overdue tasks!' : 'No tasks assigned matching filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When your Team Lead or Project Manager assigns work to you, it will appear here for time tracking and status updates.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isRunning = activeTimer.isRunning && activeTimer.entry?.taskId == task.id;

                    return _MyTaskCard(task: task, isRunningTimer: isRunning);
                  },
                );
              },
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKpis(List<TaskItem> tasks) {
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final totalHours = tasks.fold<double>(0.0, (acc, t) => acc + t.actualHours);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard('Assigned Tasks', '${tasks.length}', Icons.assignment_outlined, AppColors.primary, cardWidth),
            _kpiCard('In Progress', '$inProgress', Icons.play_circle_outline, const Color(0xFF0284C7), cardWidth),
            _kpiCard('Hours Logged', '${totalHours.toStringAsFixed(1)}h', Icons.timer_outlined, AppColors.emerald, cardWidth),
            _kpiCard('Overdue Tasks', '$overdue', Icons.warning_amber_rounded, overdue > 0 ? AppColors.rose : AppColors.secondary, cardWidth),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String status, String label) {
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
          color: isSelected ? color : AppColors.surfaceHover,
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

  Widget _buildReviewQueue(BuildContext context, AsyncValue<List<TaskItem>> queueAsync) {
    return queueAsync.when(
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
            Text(ApiException.cleanMessage(err), style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(reviewQueueProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (queue) {
        if (queue.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.only(top: 30),
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 40, color: AppColors.emerald),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Review Queue Clear!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are currently no tasks submitted for your review. When assignees complete work and submit tasks for approval, they will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: queue.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = queue[index];
            return _ReviewQueueTaskCard(task: task);
          },
        );
      },
    );
  }
}

class _ActiveTimerHeroCard extends ConsumerWidget {
  const _ActiveTimerHeroCard({
    required this.entry,
    required this.timerState,
  });

  final TimeEntryItem entry;
  final ActiveTimerState timerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaused = timerState.isPaused;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaused
              ? [const Color(0xFFD97706), const Color(0xFFB45309)]
              : [AppColors.primary, const Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPaused ? const Color(0xFFD97706) : AppColors.primary).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaused ? Icons.pause : Icons.timer,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaused ? 'WORK TIME RECORDING PAUSED' : 'CURRENTLY RECORDING WORK TIME',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.taskTitle ?? 'Task #${entry.taskId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.projectName != null)
                  Text(
                    'Project: ${entry.projectName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Live digital clock with paused indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPaused) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'PAUSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                Text(
                  timerState.formattedTime,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Pause / Resume Button
          if (isPaused)
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(activeTimerProvider.notifier).resumeTimer(entry.taskId);
                ref.invalidate(myTasksProvider);
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(activeTimerProvider.notifier).pauseTimer(entry.taskId);
                ref.invalidate(myTasksProvider);
              },
              icon: const Icon(Icons.pause, size: 16),
              label: const Text('Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          const SizedBox(width: 8),

          // Stop button
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(activeTimerProvider.notifier).stopTimer(entry.taskId);
              ref.invalidate(myTasksProvider);
            },
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.rose,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTaskCard extends ConsumerWidget {
  const _MyTaskCard({
    required this.task,
    required this.isRunningTimer,
  });

  final TaskItem task;
  final bool isRunningTimer;

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

                    // Priority
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

                    const Spacer(),

                    // Timer action
                    if (isRunningTimer)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(activeTimerProvider.notifier).stopTimer(task.id);
                          ref.invalidate(myTasksProvider);
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
                    else if (!task.isCompleted)
                      IconButton(
                        tooltip: 'Start Live Timer',
                        icon: const Icon(Icons.play_circle_outline, size: 22),
                        color: AppColors.primary,
                        onPressed: () async {
                          try {
                            await ref.read(activeTimerProvider.notifier).startTimer(task.id);
                            ref.invalidate(myTasksProvider);
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(context, e);
                            }
                          }
                        },
                      ),

                    // Open Project link
                    IconButton(
                      tooltip: 'Open Project Workspace',
                      icon: const Icon(Icons.launch, size: 18),
                      color: AppColors.textMuted,
                      onPressed: () {
                        context.go('/projects/${task.projectId}');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Task title
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

                // Footer: Deadline, Log Manual Time, Hours
                Row(
                  children: [
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

                    if (task.isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Overdue',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.rose),
                        ),
                      ),
                    ] else if (task.isDueToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Due Today',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ),
                    ] else if (task.isDueSoon) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Due in ${task.daysRemaining}d',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],

                    if (task.isCompleted && task.deadlineVariance != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: task.deadlineVarianceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.deadlineVarianceDisplay,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: task.deadlineVarianceColor),
                        ),
                      ),
                    ],

                    const SizedBox(width: 14),

                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ManualTimeDialog(task: task),
                        );
                      },
                      icon: const Icon(Icons.add_alarm, size: 13),
                      label: const Text('Log Hours'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${task.actualHours.toStringAsFixed(1)}h',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
          ),
        ),
      ),
    );
  }
}

class _ReviewQueueTaskCard extends ConsumerWidget {
  const _ReviewQueueTaskCard({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
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
            ).then((_) {
              ref.invalidate(reviewQueueProvider);
              ref.invalidate(myTasksProvider);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 12, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Pending Review',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: task.priorityColor,
                        ),
                      ),
                    ),
                    if (task.projectName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          task.projectName!,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    if (task.waitingTimeHuman != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 12, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              task.waitingTimeHuman!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => TaskDetailDialog(taskId: task.id),
                        ).then((_) {
                          ref.invalidate(reviewQueueProvider);
                          ref.invalidate(myTasksProvider);
                        });
                      },
                      icon: const Icon(Icons.rate_review, size: 14),
                      label: const Text('Review & Decide'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (task.submittedByName != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted by: ${task.submittedByName}',
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (task.assignedToName != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Assignee: ${task.assignedToName}',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    if (task.dueDate != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: task.isOverdue ? AppColors.rose : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${task.dueDate}',
                            style: TextStyle(
                              fontSize: 11,
                              color: task.isOverdue ? AppColors.rose : AppColors.textSecondary,
                              fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${task.actualHours.toStringAsFixed(1)}h logged',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        if (task.estimatedHours != null)
                          Text(
                            ' / ${task.estimatedHours}h est.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
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
