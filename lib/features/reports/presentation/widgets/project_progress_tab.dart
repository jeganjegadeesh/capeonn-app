import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';
import 'report_kpi_card.dart';

class ProjectProgressTab extends ConsumerWidget {
  const ProjectProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(projectProgressReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return progressAsync.when(
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
                    title: 'Total Projects',
                    value: '${report.summary.totalProjects}',
                    subtitle: '${report.summary.completedCount} finished · ${report.summary.avgProgressPercent.toStringAsFixed(0)}% avg progress',
                    icon: Icons.folder_special_rounded,
                    accentColor: AppColors.primary,
                  ),
                  ReportKpiCard(
                    title: 'On-Track Projects',
                    value: '${report.summary.onTrackCount}',
                    subtitle: 'Within planned schedule',
                    icon: Icons.check_circle_rounded,
                    accentColor: AppColors.emerald,
                  ),
                  ReportKpiCard(
                    title: 'Due Soon (≤7d)',
                    value: '${report.summary.dueSoonCount}',
                    subtitle: 'Approaching project milestone',
                    icon: Icons.alarm_rounded,
                    accentColor: AppColors.amber,
                  ),
                  ReportKpiCard(
                    title: 'Overdue Projects',
                    value: '${report.summary.overdueCount}',
                    subtitle: 'Exceeded project deadline',
                    icon: Icons.warning_amber_rounded,
                    accentColor: AppColors.rose,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Active Projects Progress & Health',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 14),

              if (report.items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No projects found for the current filters.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              else
                LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1000 ? 3 : (width >= 620 ? 2 : 1);
                  return GridView.builder(
                    itemCount: report.items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 175,
                    ),
                    itemBuilder: (context, index) {
                      return _buildProjectCard(report.items[index], isDark);
                    },
                  );
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
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Failed to load project progress report: $err'),
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectProgressItem p, bool isDark) {
    final healthColor = switch (p.health) {
      'completed' => AppColors.emerald,
      'due_soon' => AppColors.amber,
      'overdue' => AppColors.rose,
      _ => AppColors.primary,
    };

    final healthLabel = switch (p.health) {
      'completed' => 'Completed',
      'due_soon' => 'Due Soon',
      'overdue' => 'Overdue',
      _ => 'On Track',
    };

    final progressRatio = (p.progressPercent / 100.0).clamp(0.0, 1.0);

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.code ?? 'PRJ'} · ${p.departmentName ?? 'General'} · Lead: ${p.teamLeadName ?? 'None'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  healthLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: healthColor),
                ),
              ),
            ],
          ),

          // Progress Bar & Counts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${p.completedTasks} / ${p.totalTasks} tasks completed',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  ),
                  Text(
                    '${p.progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: healthColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressRatio,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),
              ),
            ],
          ),

          // Hours and Deadline info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.actualHours.toStringAsFixed(1)}h logged (${p.estimatedHours.toStringAsFixed(0)}h est)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                p.daysRemaining != null
                    ? (p.daysRemaining! < 0 ? '+${-p.daysRemaining!}d late' : '${p.daysRemaining}d left')
                    : 'No deadline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: (p.daysRemaining != null && p.daysRemaining! < 0) ? AppColors.rose : healthColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
