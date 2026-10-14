import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';
import 'report_kpi_card.dart';

class TaskCompletionTab extends ConsumerWidget {
  const TaskCompletionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionAsync = ref.watch(taskCompletionReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return completionAsync.when(
      data: (report) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary KPI Grid
              ReportKpiGrid(
                children: [
                  ReportKpiCard(
                    title: 'Tasks Delivered',
                    value: '${report.summary.completedTasks}',
                    subtitle: '${report.summary.totalTasks} total tasks in period',
                    icon: Icons.check_circle_outline,
                    accentColor: AppColors.emerald,
                  ),
                  ReportKpiCard(
                    title: 'Throughput Rate',
                    value: '${report.summary.completionRate.toStringAsFixed(1)}%',
                    subtitle: 'Completed vs total backlog',
                    icon: Icons.speed_rounded,
                    accentColor: AppColors.primary,
                  ),
                  ReportKpiCard(
                    title: 'Avg Turnaround',
                    value: '${report.summary.avgTurnaroundHours.toStringAsFixed(1)}h',
                    subtitle: 'From creation to sign-off',
                    icon: Icons.timelapse_rounded,
                    accentColor: AppColors.purple,
                  ),
                  ReportKpiCard(
                    title: '1st-Time Review Pass',
                    value: '${report.summary.firstTimePassRate.toStringAsFixed(1)}%',
                    subtitle: '${report.summary.firstTimeApproved} passed · ${report.summary.changesRequested} rework',
                    icon: Icons.rate_review_outlined,
                    accentColor: AppColors.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Status Pipeline Distribution
              _buildStatusPipeline(report.statusDistribution, report.summary.totalTasks, isDark),

              const SizedBox(height: 24),

              // Velocity Timeline Chart
              _buildVelocityTimeline(report.velocityTimeline, isDark),
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
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Failed to load task completion report: $err'),
        ),
      ),
    );
  }

  Widget _buildStatusPipeline(StatusDistribution dist, int totalTasks, bool isDark) {
    final stages = [
      {'label': 'Backlog', 'count': dist.backlog, 'color': const Color(0xFF94A3B8)},
      {'label': 'Assigned', 'count': dist.assigned, 'color': AppColors.primaryLight},
      {'label': 'In Progress', 'count': dist.inProgress, 'color': AppColors.primary},
      {'label': 'Review', 'count': dist.review, 'color': AppColors.purple},
      {'label': 'Changes Req.', 'count': dist.changesRequired, 'color': AppColors.amber},
      {'label': 'Completed', 'count': dist.completed, 'color': AppColors.emerald},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
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
                child: Text(
                  'Task Status Pipeline Distribution',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: $totalTasks tasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Multi-color stacked progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: stages.map((s) {
                  final cnt = s['count'] as int;
                  final flex = totalTasks > 0 ? (cnt / totalTasks * 1000).toInt() : 0;
                  if (flex <= 0) return const SizedBox.shrink();
                  return Expanded(
                    flex: flex,
                    child: Container(color: s['color'] as Color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stage legend chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: stages.map((s) {
              final cnt = s['count'] as int;
              final pct = totalTasks > 0 ? (cnt / totalTasks * 100).toStringAsFixed(1) : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s['label']}: $cnt ($pct%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityTimeline(List<VelocityTimelineItem> timeline, bool isDark) {
    final maxCount = timeline.fold<int>(0, (max, item) => item.completedCount > max ? item.completedCount : max);
    final displayMax = maxCount > 0 ? maxCount : 5;

    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            'Daily Task Completion Velocity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          if (timeline.isEmpty)
            const Center(child: Text('No timeline data available.'))
          else
            SizedBox(
              height: 140,
              child: LayoutBuilder(builder: (context, constraints) {
                final minWidth = timeline.length * 32.0;
                final shouldScroll = minWidth > constraints.maxWidth;

                final chartRow = Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: timeline.map((item) {
                    final heightRatio = (item.completedCount / displayMax).clamp(0.04, 1.0);
                    final dayLabel = item.date.length >= 10 ? item.date.substring(8, 10) : item.date;

                    final barWidget = Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.completedCount > 0)
                            Text(
                              '${item.completedCount}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: 80 * heightRatio,
                            decoration: BoxDecoration(
                              color: item.completedCount > 0 ? AppColors.primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );

                    return shouldScroll
                        ? SizedBox(width: 28, child: barWidget)
                        : Expanded(child: barWidget);
                  }).toList(),
                );

                return shouldScroll
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(width: minWidth, child: chartRow),
                      )
                    : chartRow;
              }),
            ),
        ],
      ),
    );
  }
}
