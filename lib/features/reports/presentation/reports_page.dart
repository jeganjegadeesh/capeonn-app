import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/file_download_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/report_controller.dart';
import '../data/repositories/report_repository.dart';
import 'widgets/dashboard_overview_tab.dart';
import 'widgets/employee_workload_tab.dart';
import 'widgets/overdue_tasks_tab.dart';
import 'widgets/project_progress_tab.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/task_completion_tab.dart';
import 'widgets/team_performance_tab.dart';
import 'widgets/time_variance_tab.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded, size: 18)),
    Tab(text: 'Workload', icon: Icon(Icons.groups_rounded, size: 18)),
    Tab(text: 'Completion', icon: Icon(Icons.task_alt_rounded, size: 18)),
    Tab(text: 'Time Variance', icon: Icon(Icons.compare_arrows_rounded, size: 18)),
    Tab(text: 'Overdue Tasks', icon: Icon(Icons.warning_amber_rounded, size: 18)),
    Tab(text: 'Projects', icon: Icon(Icons.folder_special_rounded, size: 18)),
    Tab(text: 'Team Performance', icon: Icon(Icons.verified_rounded, size: 18)),
  ];

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(activeReportTabProvider);
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialTab);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(activeReportTabProvider.notifier).setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final currentTabIndex = ref.read(activeReportTabProvider);
        final defaultType = switch (currentTabIndex) {
          1 => 'workload',
          2 => 'task_completion',
          3 => 'time_variance',
          4 => 'overdue_tasks',
          5 => 'project_progress',
          6 => 'team_performance',
          _ => 'workload',
        };

        String selectedType = defaultType;

        return StatefulBuilder(builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text('Export Analytics CSV', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the dataset you want to export with your current active date and department filters:',
                    style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'workload', child: Text('Employee Workload Matrix')),
                          DropdownMenuItem(value: 'task_completion', child: Text('Task Completion Timeline')),
                          DropdownMenuItem(value: 'time_variance', child: Text('Estimated vs Actual Time Variance')),
                          DropdownMenuItem(value: 'overdue_tasks', child: Text('Overdue Deliverables & Aging')),
                          DropdownMenuItem(value: 'project_progress', child: Text('Project Progress & Milestones')),
                          DropdownMenuItem(value: 'team_performance', child: Text('Team Performance Scorecards')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download, size: 16),
                label: const Text('Download CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleCsvDownload(selectedType);
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _handleCsvDownload(String selectedType) async {
    try {
      if (!mounted) return;
      AppToast.info(context, 'Generating CSV export...');

      final filter = ref.read(reportFilterProvider);
      final repo = ref.read(reportRepositoryProvider);
      final csv = await repo.exportCsv(selectedType, filter);

      if (csv.trim().isEmpty) {
        if (!mounted) return;
        AppToast.error(context, 'Export returned no data');
        return;
      }

      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = '${selectedType}_report_$dateStr.csv';
      // Prepend UTF-8 BOM so Excel and other spreadsheet tools render characters cleanly
      final bom = [0xEF, 0xBB, 0xBF];
      final fileBytes = [...bom, ...utf8.encode(csv)];

      if (!mounted) return;
      await FileDownloadService.saveFileBytes(
        context: context,
        bytes: fileBytes,
        fileName: fileName,
        mimeType: 'text/csv',
        autoOpen: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e, title: 'Export Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(activeReportTabProvider, (prev, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 600 ? 14.0 : 24.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports & Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Management Business Intelligence, Team Performance & Workload Analytics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh Reports',
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: () {
                    ref.invalidate(reportsDashboardSummaryProvider);
                    ref.invalidate(employeeWorkloadReportProvider);
                    ref.invalidate(taskCompletionReportProvider);
                    ref.invalidate(timeVarianceReportProvider);
                    ref.invalidate(overdueTasksReportProvider);
                    ref.invalidate(projectProgressReportProvider);
                    ref.invalidate(teamPerformanceReportProvider);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Global Filter Bar
            ReportFilterBar(onExportPressed: _showExportDialog),

            const SizedBox(height: 14),

            // Sub-Navigation Tabs Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                tabs: _tabs,
              ),
            ),

            const SizedBox(height: 8),

            // Tab Views Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  DashboardOverviewTab(),
                  EmployeeWorkloadTab(),
                  TaskCompletionTab(),
                  TimeVarianceTab(),
                  OverdueTasksTab(),
                  ProjectProgressTab(),
                  TeamPerformanceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
