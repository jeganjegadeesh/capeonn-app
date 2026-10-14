import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';
import 'report_kpi_card.dart';

class TimeVarianceTab extends ConsumerStatefulWidget {
  const TimeVarianceTab({super.key});

  @override
  ConsumerState<TimeVarianceTab> createState() => _TimeVarianceTabState();
}

class _TimeVarianceTabState extends ConsumerState<TimeVarianceTab> {
  String _selectedClassFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final varianceAsync = ref.watch(timeVarianceReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return varianceAsync.when(
      data: (report) {
        final filteredItems = report.items.where((i) {
          if (_selectedClassFilter != 'all' && i.classification != _selectedClassFilter) {
            return false;
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary KPI Grid
              ReportKpiGrid(
                children: [
                  ReportKpiCard(
                    title: 'Total Tracked Hours',
                    value: '${report.summary.totalActualHours.toStringAsFixed(1)}h',
                    subtitle: 'Est: ${report.summary.totalEstimatedHours.toStringAsFixed(1)}h budgeted',
                    icon: Icons.access_time_filled_rounded,
                    accentColor: AppColors.primary,
                  ),
                  ReportKpiCard(
                    title: 'Net Variance',
                    value: '${report.summary.netVarianceHours > 0 ? '+' : ''}${report.summary.netVarianceHours.toStringAsFixed(1)}h',
                    subtitle: '${report.summary.overallVariancePercent > 0 ? '+' : ''}${report.summary.overallVariancePercent.toStringAsFixed(1)}% vs estimate',
                    icon: Icons.compare_arrows_rounded,
                    accentColor: report.summary.netVarianceHours > 0 ? AppColors.rose : AppColors.emerald,
                  ),
                  ReportKpiCard(
                    title: 'Early Delivered',
                    value: '${report.summary.earlyCount}',
                    subtitle: 'Finished under 90% estimate',
                    icon: Icons.trending_down_rounded,
                    accentColor: AppColors.emerald,
                  ),
                  ReportKpiCard(
                    title: 'Over Estimate',
                    value: '${report.summary.overTimeCount}',
                    subtitle: 'Exceeded 110% estimate',
                    icon: Icons.trending_up_rounded,
                    accentColor: AppColors.rose,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Filter Switcher
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterTab('all', 'All Tasks (${report.items.length})', isDark),
                    const SizedBox(width: 8),
                    _buildFilterTab('early', 'Early (<90%) (${report.summary.earlyCount})', isDark),
                    const SizedBox(width: 8),
                    _buildFilterTab('on_time', 'On-Time (±10%) (${report.summary.onTimeCount})', isDark),
                    const SizedBox(width: 8),
                    _buildFilterTab('over_time', 'Overtime (>110%) (${report.summary.overTimeCount})', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Task Variance List
              if (filteredItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No tasks match the selected classification.',
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
                    return _buildVarianceRow(item, isDark);
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
          child: Text('Failed to load time variance report: $err'),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String key, String label, bool isDark) {
    final isSelected = _selectedClassFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedClassFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF131C2E) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildVarianceRow(TimeVarianceItem item, bool isDark) {
    final badgeColor = switch (item.classification) {
      'early' => AppColors.emerald,
      'on_time' => AppColors.primary,
      'over_time' => AppColors.rose,
      _ => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    };

    final badgeLabel = switch (item.classification) {
      'early' => 'Early',
      'on_time' => 'On-Time',
      'over_time' => 'Overtime',
      _ => 'Incomplete',
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
              color: badgeColor.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.actualHours.toStringAsFixed(1)}h actual / ${item.estimatedHours.toStringAsFixed(1)}h est',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.varianceHours > 0 ? '+' : ''}${item.varianceHours.toStringAsFixed(1)}h (${item.variancePercentage > 0 ? '+' : ''}${item.variancePercentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
