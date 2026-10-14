import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';
import 'report_kpi_card.dart';

class TeamPerformanceTab extends ConsumerWidget {
  const TeamPerformanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(teamPerformanceReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return performanceAsync.when(
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
                    title: 'Active Contributors',
                    value: '${report.summary.totalMembers}',
                    subtitle: 'Visible team members',
                    icon: Icons.badge_outlined,
                    accentColor: AppColors.primary,
                  ),
                  ReportKpiCard(
                    title: 'Tasks Delivered',
                    value: '${report.summary.totalTasksCompleted}',
                    subtitle: 'Completed deliverables',
                    icon: Icons.task_alt_rounded,
                    accentColor: AppColors.emerald,
                  ),
                  ReportKpiCard(
                    title: 'Avg On-Time Rate',
                    value: '${report.summary.avgOnTimeRate.toStringAsFixed(1)}%',
                    subtitle: 'Punctuality scorecard',
                    icon: Icons.verified_rounded,
                    accentColor: AppColors.secondary,
                  ),
                  ReportKpiCard(
                    title: 'Total Logged Hours',
                    value: '${report.summary.totalHoursLogged.toStringAsFixed(1)}h',
                    subtitle: 'Tracked team working hours',
                    icon: Icons.timer_outlined,
                    accentColor: AppColors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Member Performance Scorecards',
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
                      'No team performance records found.',
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
                      return _buildMemberScorecard(report.items[index], isDark);
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
          child: Text('Failed to load team performance data: $err'),
        ),
      ),
    );
  }

  Widget _buildMemberScorecard(TeamPerformanceItem member, bool isDark) {
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${member.employeeCode ?? 'Emp'} · ${member.departmentName ?? 'General'}',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${member.onTimeRatePercentage.toStringAsFixed(0)}% On-Time',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald),
                ),
              ),
            ],
          ),

          // Punctuality & Quality Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                'Delivered',
                '${member.completedTasksCount} / ${member.assignedTasksCount}',
                AppColors.primary,
                isDark,
              ),
              _buildMiniMetric(
                '1st-Time Pass',
                '${member.firstTimeApprovalRate.toStringAsFixed(0)}%',
                AppColors.secondary,
                isDark,
              ),
              _buildMiniMetric(
                'Logged Time',
                '${member.totalLoggedHours.toStringAsFixed(1)}h',
                AppColors.purple,
                isDark,
              ),
            ],
          ),

          // Avg duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${member.onTimeTasksCount} on-time · ${member.lateTasksCount} late',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Avg: ${member.avgTaskDurationHours.toStringAsFixed(1)}h / task',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      ],
    );
  }
}
