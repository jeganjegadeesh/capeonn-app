import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';
import 'report_kpi_card.dart';

class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportsDashboardSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return summaryAsync.when(
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Grid
              ReportKpiGrid(
                children: [
                    ReportKpiCard(
                      title: 'Active Projects',
                      value: '${data.projects.active}',
                      subtitle: '${data.projects.total} total · ${data.projects.overdue} overdue',
                      icon: Icons.folder_special_rounded,
                      accentColor: AppColors.primary,
                      trailingBadge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: data.projects.overdue > 0
                              ? AppColors.rose.withValues(alpha: isDark ? 0.25 : 0.12)
                              : AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.projects.overdue > 0 ? '${data.projects.overdue} Overdue' : 'Healthy',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: data.projects.overdue > 0 ? AppColors.rose : AppColors.emerald,
                          ),
                        ),
                      ),
                      onTap: () => ref.read(activeReportTabProvider.notifier).setTab(5),
                    ),
                    ReportKpiCard(
                      title: 'Task Completion Rate',
                      value: '${data.tasks.completionRate.toStringAsFixed(1)}%',
                      subtitle: '${data.tasks.completed} / ${data.tasks.total} delivered · ${data.tasks.onTimeRate.toStringAsFixed(0)}% on-time',
                      icon: Icons.task_alt_rounded,
                      accentColor: AppColors.emerald,
                      trailingBadge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${data.tasks.inProgress} In Progress',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                      onTap: () => ref.read(activeReportTabProvider.notifier).setTab(2),
                    ),
                    ReportKpiCard(
                      title: 'Logged Working Hours',
                      value: '${data.hours.trackedHours.toStringAsFixed(1)}h',
                      subtitle: 'Est: ${data.hours.estimatedHours.toStringAsFixed(0)}h · Act: ${data.hours.actualHours.toStringAsFixed(0)}h',
                      icon: Icons.timer_outlined,
                      accentColor: AppColors.purple,
                      onTap: () => ref.read(activeReportTabProvider.notifier).setTab(3),
                    ),
                    ReportKpiCard(
                      title: 'Team Workload',
                      value: '${data.workloadSummary.totalEmployees}',
                      subtitle: '${data.workloadSummary.overloadedCount} overloaded · ${data.workloadSummary.normalCount} optimal',
                      icon: Icons.groups_rounded,
                      accentColor: data.workloadSummary.overloadedCount > 0 ? AppColors.amber : AppColors.secondary,
                      trailingBadge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (data.workloadSummary.overloadedCount > 0 ? AppColors.amber : AppColors.secondary)
                              .withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${data.workloadSummary.overloadedCount} Alert',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: data.workloadSummary.overloadedCount > 0 ? AppColors.amber : AppColors.secondary,
                          ),
                        ),
                      ),
                      onTap: () => ref.read(activeReportTabProvider.notifier).setTab(1),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Attention & Critical Items Row
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildOverdueTasksCard(context, data.attention.urgentOverdueTasks, ref, isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDueSoonProjectsCard(context, data.attention.dueSoonProjects, ref, isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStuckReviewsCard(context, data.attention.stuckReviews, ref, isDark)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildOverdueTasksCard(context, data.attention.urgentOverdueTasks, ref, isDark),
                      const SizedBox(height: 14),
                      _buildDueSoonProjectsCard(context, data.attention.dueSoonProjects, ref, isDark),
                      const SizedBox(height: 14),
                      _buildStuckReviewsCard(context, data.attention.stuckReviews, ref, isDark),
                    ],
                  );
                }
              }),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.rose),
              const SizedBox(height: 12),
              Text('Failed to load dashboard analytics: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(reportsDashboardSummaryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueTasksCard(
    BuildContext context,
    List<UrgentOverdueTaskItem> tasks,
    WidgetRef ref,
    bool isDark,
  ) {
    return _AttentionContainer(
      title: 'Urgent Overdue Tasks',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.rose,
      actionText: 'View All',
      onAction: () => ref.read(activeReportTabProvider.notifier).setTab(4),
      isDark: isDark,
      child: tasks.isEmpty
          ? const _EmptyAttentionState(message: 'No overdue tasks! Team is fully on track.')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final t = tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${t.daysOverdue}d',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.rose),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${t.projectName ?? 'No Project'} · ${t.assigneeName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDueSoonProjectsCard(
    BuildContext context,
    List<DueSoonProjectItem> projects,
    WidgetRef ref,
    bool isDark,
  ) {
    return _AttentionContainer(
      title: 'Projects Approaching Deadline',
      icon: Icons.alarm_rounded,
      iconColor: AppColors.amber,
      actionText: 'View All',
      onAction: () => ref.read(activeReportTabProvider.notifier).setTab(5),
      isDark: isDark,
      child: projects.isEmpty
          ? const _EmptyAttentionState(message: 'No project deadlines within 7 days.')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final p = projects[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${p.daysRemaining}d left',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Lead: ${p.teamLeadName ?? 'Unassigned'} · ${p.department ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStuckReviewsCard(
    BuildContext context,
    List<StuckReviewItem> reviews,
    WidgetRef ref,
    bool isDark,
  ) {
    return _AttentionContainer(
      title: 'Reviews Pending > 48h',
      icon: Icons.hourglass_top_rounded,
      iconColor: AppColors.secondary,
      actionText: 'Review Queue',
      onAction: () => ref.read(activeReportTabProvider.notifier).setTab(2),
      isDark: isDark,
      child: reviews.isEmpty
          ? const _EmptyAttentionState(message: 'All task reviews are processed promptly.')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final r = reviews[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${r.hoursPending}h',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Submitted by ${r.assigneeName ?? 'Dev'} · ${r.projectName ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AttentionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String actionText;
  final VoidCallback onAction;
  final Widget child;
  final bool isDark;

  const _AttentionContainer({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.actionText,
    required this.onAction,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onAction,
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyAttentionState extends StatelessWidget {
  final String message;
  const _EmptyAttentionState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
