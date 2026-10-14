import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/report_models.dart';
import '../data/repositories/report_repository.dart';

class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => const ReportFilter(preset: 'this_month');

  void setFilter(ReportFilter filter) => state = filter;
  void update(ReportFilter Function(ReportFilter) fn) => state = fn(state);
}

final reportFilterProvider = NotifierProvider<ReportFilterNotifier, ReportFilter>(ReportFilterNotifier.new);

class ActiveReportTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final activeReportTabProvider = NotifierProvider<ActiveReportTabNotifier, int>(ActiveReportTabNotifier.new);

final reportsDashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummaryData>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getDashboardSummary(filter);
});

final employeeWorkloadReportProvider = FutureProvider.autoDispose<EmployeeWorkloadReport>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getEmployeeWorkload(filter);
});

final taskCompletionReportProvider = FutureProvider.autoDispose<TaskCompletionReport>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getTaskCompletionReport(filter);
});

final timeVarianceReportProvider = FutureProvider.autoDispose<TimeVarianceReport>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getTimeVarianceReport(filter);
});

final overdueTasksReportProvider = FutureProvider.autoDispose<OverdueTasksReport>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getOverdueTasksReport(filter);
});

final projectProgressReportProvider = FutureProvider.autoDispose<ProjectProgressReport>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getProjectProgressReport(filter);
});

final teamPerformanceReportProvider = FutureProvider.autoDispose<TeamPerformanceReport>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);
  return repo.getTeamPerformanceReport(filter);
});
