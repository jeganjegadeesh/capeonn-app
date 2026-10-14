import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';
import 'report_kpi_card.dart';

class OverdueTasksTab extends ConsumerStatefulWidget {
  const OverdueTasksTab({super.key});

  @override
  ConsumerState<OverdueTasksTab> createState() => _OverdueTasksTabState();
}

class _OverdueTasksTabState extends ConsumerState<OverdueTasksTab> {
  String _selectedBucketFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final overdueAsync = ref.watch(overdueTasksReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return overdueAsync.when(
      data: (report) {
        final filteredItems = report.items.where((i) {
          if (_selectedBucketFilter != 'all' && i.agingBucket != _selectedBucketFilter) {
            return false;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aging Buckets Grid
              ReportKpiGrid(
                children: [
                  ReportKpiCard(
                    title: '1–3 Days Overdue',
                    value: '${report.summary.agingBuckets.bucket1To3}',
                    subtitle: 'Recent slip, quick to recover',
                    icon: Icons.hourglass_bottom_rounded,
                    accentColor: AppColors.amber,
                    onTap: () => setState(() => _selectedBucketFilter = '1-3 days'),
                  ),
                  ReportKpiCard(
                    title: '4–7 Days Overdue',
                    value: '${report.summary.agingBuckets.bucket4To7}',
                    subtitle: 'Needs TL intervention',
                    icon: Icons.warning_amber_rounded,
                    accentColor: const Color(0xFFF97316), // Orange
                    onTap: () => setState(() => _selectedBucketFilter = '4-7 days'),
                  ),
                  ReportKpiCard(
                    title: '8–14 Days Overdue',
                    value: '${report.summary.agingBuckets.bucket8To14}',
                    subtitle: 'Critical delay, escalation',
                    icon: Icons.report_problem_rounded,
                    accentColor: AppColors.rose,
                    onTap: () => setState(() => _selectedBucketFilter = '8-14 days'),
                  ),
                  ReportKpiCard(
                    title: '15+ Days Overdue',
                    value: '${report.summary.agingBuckets.bucket15Plus}',
                    subtitle: 'Severely overdue bottleneck',
                    icon: Icons.error_rounded,
                    accentColor: const Color(0xFFB91C1C), // Deep Red
                    onTap: () => setState(() => _selectedBucketFilter = '15+ days'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Bucket Filter & Priority Breakdown Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildBucketFilter('all', 'All Overdue (${report.summary.totalOverdue})', isDark),
                    const SizedBox(width: 8),
                    _buildBucketFilter('1-3 days', '1-3d (${report.summary.agingBuckets.bucket1To3})', isDark),
                    const SizedBox(width: 8),
                    _buildBucketFilter('4-7 days', '4-7d (${report.summary.agingBuckets.bucket4To7})', isDark),
                    const SizedBox(width: 8),
                    _buildBucketFilter('8-14 days', '8-14d (${report.summary.agingBuckets.bucket8To14})', isDark),
                    const SizedBox(width: 8),
                    _buildBucketFilter('15+ days', '15+d (${report.summary.agingBuckets.bucket15Plus})', isDark),
                    const SizedBox(width: 16),
                    _buildPriorityPill('Urgent', report.summary.priorityBreakdown['urgent'] ?? 0, AppColors.rose, isDark),
                    const SizedBox(width: 6),
                    _buildPriorityPill('High', report.summary.priorityBreakdown['high'] ?? 0, AppColors.amber, isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Overdue Tasks List
              if (filteredItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No overdue tasks in this bucket.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildOverdueRow(item, isDark);
                  },
                ),
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
          child: Text('Failed to load overdue tasks: $err'),
        ),
      ),
    );
  }

  Widget _buildBucketFilter(String key, String label, bool isDark) {
    final isSelected = _selectedBucketFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedBucketFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF131C2E) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityPill(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildOverdueRow(OverdueTaskItem item, bool isDark) {
    final priorityColor = switch (item.priority) {
      'urgent' => AppColors.rose,
      'high' => AppColors.amber,
      'medium' => AppColors.primary,
      _ => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${item.daysOverdue}d',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.rose),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.priority.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.projectCode ?? 'PRJ'} · ${item.projectName ?? ''} · Assignee: ${item.assigneeName}',
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
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Due ${item.dueDate ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.rose),
              ),
              const SizedBox(height: 2),
              Text(
                item.agingBucket,
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
