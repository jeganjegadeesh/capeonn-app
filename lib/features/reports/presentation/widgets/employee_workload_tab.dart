import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/report_controller.dart';
import '../../data/models/report_models.dart';

class EmployeeWorkloadTab extends ConsumerStatefulWidget {
  const EmployeeWorkloadTab({super.key});

  @override
  ConsumerState<EmployeeWorkloadTab> createState() => _EmployeeWorkloadTabState();
}

class _EmployeeWorkloadTabState extends ConsumerState<EmployeeWorkloadTab> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final workloadAsync = ref.watch(employeeWorkloadReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return workloadAsync.when(
      data: (report) {
        final filteredItems = report.items.where((item) {
          if (_selectedStatusFilter != 'all' && item.workloadStatus != _selectedStatusFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return item.name.toLowerCase().contains(q) ||
                item.email.toLowerCase().contains(q) ||
                (item.employeeCode?.toLowerCase().contains(q) ?? false) ||
                (item.departmentName?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Counters Bar
              _buildSummaryHeader(report.summary, isDark),
              const SizedBox(height: 16),

              // Search & Status Filter Row
              LayoutBuilder(builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final searchField = TextField(
                  decoration: InputDecoration(
                    hintText: 'Search employees by name, code or department...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF131C2E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                );

                final filterDropdown = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isDense: true,
                      dropdownColor: isDark ? const Color(0xFF131C2E) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Workloads', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'overloaded', child: Text('Overloaded (>5 tasks / >40h)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'near_capacity', child: Text('Near Capacity', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'normal', child: Text('Optimal / Normal', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'underutilized', child: Text('Underutilized', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatusFilter = val);
                      },
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      filterDropdown,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 12),
                    filterDropdown,
                  ],
                );
              }),
              const SizedBox(height: 16),

              // Employees Grid / List
              if (filteredItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No employees match the selected workload filter.',
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
                    itemCount: filteredItems.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 165,
                    ),
                    itemBuilder: (context, index) {
                      return _buildEmployeeCard(filteredItems[index], isDark);
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
          child: Text('Failed to load workload data: $err'),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(WorkloadSummaryStats summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildPill('Total: ${summary.totalEmployees}', AppColors.primary, isDark),
          _buildPill('Overloaded: ${summary.overloadedCount}', AppColors.rose, isDark),
          _buildPill('Near Capacity: ${summary.nearCapacityCount}', AppColors.amber, isDark),
          _buildPill('Optimal: ${summary.normalCount}', AppColors.emerald, isDark),
          _buildPill('Underutilized: ${summary.underutilizedCount}', isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), isDark),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeWorkloadItem emp, bool isDark) {
    final statusColor = switch (emp.workloadStatus) {
      'overloaded' => AppColors.rose,
      'near_capacity' => AppColors.amber,
      'normal' => AppColors.emerald,
      _ => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    };

    final statusLabel = switch (emp.workloadStatus) {
      'overloaded' => 'Overloaded',
      'near_capacity' => 'Near Capacity',
      'normal' => 'Optimal',
      _ => 'Underutilized',
    };

    // Calculate backlog load ratio (against 40h standard week)
    final loadRatio = (emp.backlogHours / 40.0).clamp(0.0, 1.0);

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
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${emp.employeeCode ?? 'Emp'} · ${emp.departmentName ?? 'General'}',
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
                  color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          // Active tasks & Backlog Hours Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${emp.activeTasksCount} active tasks (${emp.inProgressTasksCount} IP, ${emp.inReviewTasksCount} Rev)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${emp.backlogHours.toStringAsFixed(1)}h backlog',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: loadRatio,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),

          // Logged hours this week vs this month
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Week: ${emp.loggedHoursThisWeek.toStringAsFixed(1)}h logged',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Month: ${emp.loggedHoursThisMonth.toStringAsFixed(1)}h logged',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
