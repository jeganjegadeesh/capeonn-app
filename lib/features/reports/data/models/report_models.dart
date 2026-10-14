class ReportFilter {
  final String? preset;
  final String? startDate;
  final String? endDate;
  final int? departmentId;
  final int? projectId;
  final int? assignedToId;
  final String? search;
  final String? priority;
  final String? status;
  final String? classification;

  const ReportFilter({
    this.preset = 'this_month',
    this.startDate,
    this.endDate,
    this.departmentId,
    this.projectId,
    this.assignedToId,
    this.search,
    this.priority,
    this.status,
    this.classification,
  });

  ReportFilter copyWith({
    String? preset,
    String? startDate,
    String? endDate,
    int? departmentId,
    int? projectId,
    int? assignedToId,
    String? search,
    String? priority,
    String? status,
    String? classification,
    bool clearDates = false,
    bool clearDepartment = false,
    bool clearProject = false,
  }) {
    return ReportFilter(
      preset: preset ?? this.preset,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      projectId: clearProject ? null : (projectId ?? this.projectId),
      assignedToId: assignedToId ?? this.assignedToId,
      search: search ?? this.search,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      classification: classification ?? this.classification,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (preset != null && preset!.isNotEmpty && preset != 'all_time') {
      params['preset'] = preset;
    }
    if (startDate != null && startDate!.isNotEmpty) params['start_date'] = startDate;
    if (endDate != null && endDate!.isNotEmpty) params['end_date'] = endDate;
    if (departmentId != null) params['department_id'] = departmentId;
    if (projectId != null) params['project_id'] = projectId;
    if (assignedToId != null) params['assigned_to_id'] = assignedToId;
    if (search != null && search!.trim().isNotEmpty) params['search'] = search!.trim();
    if (priority != null && priority!.isNotEmpty && priority != 'all') params['priority'] = priority;
    if (status != null && status!.isNotEmpty && status != 'all') params['status'] = status;
    if (classification != null && classification!.isNotEmpty && classification != 'all') {
      params['classification'] = classification;
    }
    return params;
  }
}

// -------------------------------------------------------------
// 1. Dashboard Overview Models
// -------------------------------------------------------------

class DashboardSummaryData {
  final ProjectsSummary projects;
  final TasksSummary tasks;
  final HoursSummary hours;
  final WorkloadSummaryStats workloadSummary;
  final AttentionItems attention;

  const DashboardSummaryData({
    required this.projects,
    required this.tasks,
    required this.hours,
    required this.workloadSummary,
    required this.attention,
  });

  factory DashboardSummaryData.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryData(
      projects: ProjectsSummary.fromJson(Map<String, dynamic>.from(json['projects'] as Map? ?? {})),
      tasks: TasksSummary.fromJson(Map<String, dynamic>.from(json['tasks'] as Map? ?? {})),
      hours: HoursSummary.fromJson(Map<String, dynamic>.from(json['hours'] as Map? ?? {})),
      workloadSummary: WorkloadSummaryStats.fromJson(Map<String, dynamic>.from(json['workload_summary'] as Map? ?? {})),
      attention: AttentionItems.fromJson(Map<String, dynamic>.from(json['attention'] as Map? ?? {})),
    );
  }
}

class ProjectsSummary {
  final int total;
  final int active;
  final int planned;
  final int onHold;
  final int completed;
  final int overdue;
  final int dueSoon;

  const ProjectsSummary({
    this.total = 0,
    this.active = 0,
    this.planned = 0,
    this.onHold = 0,
    this.completed = 0,
    this.overdue = 0,
    this.dueSoon = 0,
  });

  factory ProjectsSummary.fromJson(Map<String, dynamic> json) {
    return ProjectsSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      planned: (json['planned'] as num?)?.toInt() ?? 0,
      onHold: (json['on_hold'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      dueSoon: (json['due_soon'] as num?)?.toInt() ?? 0,
    );
  }
}

class TasksSummary {
  final int total;
  final int backlog;
  final int assigned;
  final int inProgress;
  final int review;
  final int changesRequired;
  final int completed;
  final int overdue;
  final double completionRate;
  final double onTimeRate;

  const TasksSummary({
    this.total = 0,
    this.backlog = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.review = 0,
    this.changesRequired = 0,
    this.completed = 0,
    this.overdue = 0,
    this.completionRate = 0.0,
    this.onTimeRate = 0.0,
  });

  factory TasksSummary.fromJson(Map<String, dynamic> json) {
    return TasksSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      backlog: (json['backlog'] as num?)?.toInt() ?? 0,
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      review: (json['review'] as num?)?.toInt() ?? 0,
      changesRequired: (json['changes_required'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HoursSummary {
  final double estimatedHours;
  final double actualHours;
  final double trackedHours;

  const HoursSummary({
    this.estimatedHours = 0.0,
    this.actualHours = 0.0,
    this.trackedHours = 0.0,
  });

  factory HoursSummary.fromJson(Map<String, dynamic> json) {
    return HoursSummary(
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0.0,
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0.0,
      trackedHours: (json['tracked_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AttentionItems {
  final List<UrgentOverdueTaskItem> urgentOverdueTasks;
  final List<DueSoonProjectItem> dueSoonProjects;
  final List<StuckReviewItem> stuckReviews;

  const AttentionItems({
    this.urgentOverdueTasks = const [],
    this.dueSoonProjects = const [],
    this.stuckReviews = const [],
  });

  factory AttentionItems.fromJson(Map<String, dynamic> json) {
    return AttentionItems(
      urgentOverdueTasks: (json['urgent_overdue_tasks'] as List? ?? [])
          .map((i) => UrgentOverdueTaskItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      dueSoonProjects: (json['due_soon_projects'] as List? ?? [])
          .map((i) => DueSoonProjectItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      stuckReviews: (json['stuck_reviews'] as List? ?? [])
          .map((i) => StuckReviewItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class UrgentOverdueTaskItem {
  final int id;
  final String title;
  final String priority;
  final String? dueDate;
  final int daysOverdue;
  final String? projectName;
  final String assigneeName;

  const UrgentOverdueTaskItem({
    required this.id,
    required this.title,
    required this.priority,
    this.dueDate,
    this.daysOverdue = 0,
    this.projectName,
    required this.assigneeName,
  });

  factory UrgentOverdueTaskItem.fromJson(Map<String, dynamic> json) {
    return UrgentOverdueTaskItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] as String?,
      daysOverdue: (json['days_overdue'] as num?)?.toInt() ?? 0,
      projectName: json['project_name'] as String?,
      assigneeName: json['assignee_name'] as String? ?? 'Unassigned',
    );
  }
}

class DueSoonProjectItem {
  final int id;
  final String name;
  final String? deadline;
  final int daysRemaining;
  final String? teamLeadName;
  final String? department;

  const DueSoonProjectItem({
    required this.id,
    required this.name,
    this.deadline,
    this.daysRemaining = 0,
    this.teamLeadName,
    this.department,
  });

  factory DueSoonProjectItem.fromJson(Map<String, dynamic> json) {
    return DueSoonProjectItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      deadline: json['deadline'] as String?,
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      teamLeadName: json['team_lead_name'] as String?,
      department: json['department'] as String?,
    );
  }
}

class StuckReviewItem {
  final int id;
  final String title;
  final String? submittedAt;
  final int hoursPending;
  final String? projectName;
  final String? assigneeName;
  final String? reviewerName;

  const StuckReviewItem({
    required this.id,
    required this.title,
    this.submittedAt,
    this.hoursPending = 0,
    this.projectName,
    this.assigneeName,
    this.reviewerName,
  });

  factory StuckReviewItem.fromJson(Map<String, dynamic> json) {
    return StuckReviewItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      submittedAt: json['submitted_at'] as String?,
      hoursPending: (json['hours_pending'] as num?)?.toInt() ?? 0,
      projectName: json['project_name'] as String?,
      assigneeName: json['assignee_name'] as String?,
      reviewerName: json['reviewer_name'] as String?,
    );
  }
}

// -------------------------------------------------------------
// 2. Employee Workload Models
// -------------------------------------------------------------

class EmployeeWorkloadReport {
  final WorkloadSummaryStats summary;
  final List<EmployeeWorkloadItem> items;

  const EmployeeWorkloadReport({
    required this.summary,
    required this.items,
  });

  factory EmployeeWorkloadReport.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkloadReport(
      summary: WorkloadSummaryStats.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      items: (json['items'] as List? ?? [])
          .map((i) => EmployeeWorkloadItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class WorkloadSummaryStats {
  final int totalEmployees;
  final int overloadedCount;
  final int nearCapacityCount;
  final int normalCount;
  final int underutilizedCount;

  const WorkloadSummaryStats({
    this.totalEmployees = 0,
    this.overloadedCount = 0,
    this.nearCapacityCount = 0,
    this.normalCount = 0,
    this.underutilizedCount = 0,
  });

  factory WorkloadSummaryStats.fromJson(Map<String, dynamic> json) {
    return WorkloadSummaryStats(
      totalEmployees: (json['total_employees'] ?? json['total_members'] as num?)?.toInt() ?? 0,
      overloadedCount: (json['overloaded_count'] ?? json['overloaded'] as num?)?.toInt() ?? 0,
      nearCapacityCount: (json['near_capacity_count'] ?? json['near_capacity'] as num?)?.toInt() ?? 0,
      normalCount: (json['normal_count'] ?? json['normal'] as num?)?.toInt() ?? 0,
      underutilizedCount: (json['underutilized_count'] ?? json['underutilized'] as num?)?.toInt() ?? 0,
    );
  }
}

class EmployeeWorkloadItem {
  final int userId;
  final String name;
  final String email;
  final String? employeeCode;
  final int? departmentId;
  final String? departmentName;
  final String? designationName;
  final int activeTasksCount;
  final int inProgressTasksCount;
  final int inReviewTasksCount;
  final double backlogHours;
  final double loggedHoursThisWeek;
  final double loggedHoursThisMonth;
  final String workloadStatus; // 'overloaded', 'near_capacity', 'normal', 'underutilized'

  const EmployeeWorkloadItem({
    required this.userId,
    required this.name,
    required this.email,
    this.employeeCode,
    this.departmentId,
    this.departmentName,
    this.designationName,
    this.activeTasksCount = 0,
    this.inProgressTasksCount = 0,
    this.inReviewTasksCount = 0,
    this.backlogHours = 0.0,
    this.loggedHoursThisWeek = 0.0,
    this.loggedHoursThisMonth = 0.0,
    required this.workloadStatus,
  });

  factory EmployeeWorkloadItem.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkloadItem(
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
      departmentId: (json['department_id'] as num?)?.toInt(),
      departmentName: json['department_name'] as String?,
      designationName: json['designation_name'] as String?,
      activeTasksCount: (json['active_tasks_count'] as num?)?.toInt() ?? 0,
      inProgressTasksCount: (json['in_progress_tasks_count'] as num?)?.toInt() ?? 0,
      inReviewTasksCount: (json['in_review_tasks_count'] as num?)?.toInt() ?? 0,
      backlogHours: (json['backlog_hours'] as num?)?.toDouble() ?? 0.0,
      loggedHoursThisWeek: (json['logged_hours_this_week'] as num?)?.toDouble() ?? 0.0,
      loggedHoursThisMonth: (json['logged_hours_this_month'] as num?)?.toDouble() ?? 0.0,
      workloadStatus: json['workload_status'] as String? ?? 'normal',
    );
  }
}

// -------------------------------------------------------------
// 3. Task Completion Models
// -------------------------------------------------------------

class TaskCompletionReport {
  final TaskCompletionSummary summary;
  final StatusDistribution statusDistribution;
  final List<VelocityTimelineItem> velocityTimeline;

  const TaskCompletionReport({
    required this.summary,
    required this.statusDistribution,
    required this.velocityTimeline,
  });

  factory TaskCompletionReport.fromJson(Map<String, dynamic> json) {
    return TaskCompletionReport(
      summary: TaskCompletionSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      statusDistribution: StatusDistribution.fromJson(Map<String, dynamic>.from(json['status_distribution'] as Map? ?? {})),
      velocityTimeline: (json['velocity_timeline'] as List? ?? [])
          .map((i) => VelocityTimelineItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class TaskCompletionSummary {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final double avgTurnaroundHours;
  final double firstTimePassRate;
  final int firstTimeApproved;
  final int changesRequested;

  const TaskCompletionSummary({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.completionRate = 0.0,
    this.avgTurnaroundHours = 0.0,
    this.firstTimePassRate = 0.0,
    this.firstTimeApproved = 0,
    this.changesRequested = 0,
  });

  factory TaskCompletionSummary.fromJson(Map<String, dynamic> json) {
    return TaskCompletionSummary(
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      avgTurnaroundHours: (json['avg_turnaround_hours'] as num?)?.toDouble() ?? 0.0,
      firstTimePassRate: (json['first_time_pass_rate'] as num?)?.toDouble() ?? 0.0,
      firstTimeApproved: (json['first_time_approved'] as num?)?.toInt() ?? 0,
      changesRequested: (json['changes_requested'] as num?)?.toInt() ?? 0,
    );
  }
}

class StatusDistribution {
  final int backlog;
  final int assigned;
  final int inProgress;
  final int review;
  final int changesRequired;
  final int completed;

  const StatusDistribution({
    this.backlog = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.review = 0,
    this.changesRequired = 0,
    this.completed = 0,
  });

  factory StatusDistribution.fromJson(Map<String, dynamic> json) {
    return StatusDistribution(
      backlog: (json['backlog'] as num?)?.toInt() ?? 0,
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      review: (json['review'] as num?)?.toInt() ?? 0,
      changesRequired: (json['changes_required'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
    );
  }
}

class VelocityTimelineItem {
  final String date;
  final int completedCount;

  const VelocityTimelineItem({required this.date, required this.completedCount});

  factory VelocityTimelineItem.fromJson(Map<String, dynamic> json) {
    return VelocityTimelineItem(
      date: json['date'] as String? ?? '',
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    );
  }
}

// -------------------------------------------------------------
// 4. Time Variance Models
// -------------------------------------------------------------

class TimeVarianceReport {
  final TimeVarianceSummary summary;
  final List<TimeVarianceItem> items;

  const TimeVarianceReport({
    required this.summary,
    required this.items,
  });

  factory TimeVarianceReport.fromJson(Map<String, dynamic> json) {
    return TimeVarianceReport(
      summary: TimeVarianceSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      items: (json['items'] as List? ?? [])
          .map((i) => TimeVarianceItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class TimeVarianceSummary {
  final int totalTasks;
  final double totalEstimatedHours;
  final double totalActualHours;
  final double netVarianceHours;
  final double overallVariancePercent;
  final int earlyCount;
  final int onTimeCount;
  final int overTimeCount;

  const TimeVarianceSummary({
    this.totalTasks = 0,
    this.totalEstimatedHours = 0.0,
    this.totalActualHours = 0.0,
    this.netVarianceHours = 0.0,
    this.overallVariancePercent = 0.0,
    this.earlyCount = 0,
    this.onTimeCount = 0,
    this.overTimeCount = 0,
  });

  factory TimeVarianceSummary.fromJson(Map<String, dynamic> json) {
    return TimeVarianceSummary(
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      totalEstimatedHours: (json['total_estimated_hours'] as num?)?.toDouble() ?? 0.0,
      totalActualHours: (json['total_actual_hours'] as num?)?.toDouble() ?? 0.0,
      netVarianceHours: (json['net_variance_hours'] as num?)?.toDouble() ?? 0.0,
      overallVariancePercent: (json['overall_variance_percent'] as num?)?.toDouble() ?? 0.0,
      earlyCount: (json['early_count'] as num?)?.toInt() ?? 0,
      onTimeCount: (json['on_time_count'] as num?)?.toInt() ?? 0,
      overTimeCount: (json['over_time_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimeVarianceItem {
  final int taskId;
  final String title;
  final String status;
  final String priority;
  final int? projectId;
  final String? projectName;
  final String? projectCode;
  final String assigneeName;
  final double estimatedHours;
  final double actualHours;
  final double varianceHours;
  final double variancePercentage;
  final String classification; // 'early', 'on_time', 'over_time', 'none'

  const TimeVarianceItem({
    required this.taskId,
    required this.title,
    required this.status,
    required this.priority,
    this.projectId,
    this.projectName,
    this.projectCode,
    required this.assigneeName,
    this.estimatedHours = 0.0,
    this.actualHours = 0.0,
    this.varianceHours = 0.0,
    this.variancePercentage = 0.0,
    required this.classification,
  });

  factory TimeVarianceItem.fromJson(Map<String, dynamic> json) {
    return TimeVarianceItem(
      taskId: (json['task_id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      projectId: (json['project_id'] as num?)?.toInt(),
      projectName: json['project_name'] as String?,
      projectCode: json['project_code'] as String?,
      assigneeName: json['assignee_name'] as String? ?? 'Unassigned',
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0.0,
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0.0,
      varianceHours: (json['variance_hours'] as num?)?.toDouble() ?? 0.0,
      variancePercentage: (json['variance_percentage'] as num?)?.toDouble() ?? 0.0,
      classification: json['classification'] as String? ?? 'none',
    );
  }
}

// -------------------------------------------------------------
// 5. Overdue Tasks Models
// -------------------------------------------------------------

class OverdueTasksReport {
  final OverdueSummary summary;
  final List<OverdueTaskItem> items;

  const OverdueTasksReport({
    required this.summary,
    required this.items,
  });

  factory OverdueTasksReport.fromJson(Map<String, dynamic> json) {
    return OverdueTasksReport(
      summary: OverdueSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      items: (json['items'] as List? ?? [])
          .map((i) => OverdueTaskItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class OverdueSummary {
  final int totalOverdue;
  final AgingBuckets agingBuckets;
  final Map<String, int> priorityBreakdown;

  const OverdueSummary({
    this.totalOverdue = 0,
    required this.agingBuckets,
    this.priorityBreakdown = const {},
  });

  factory OverdueSummary.fromJson(Map<String, dynamic> json) {
    final rawPriorities = json['priority_breakdown'] as Map? ?? {};
    final priorities = <String, int>{};
    rawPriorities.forEach((k, v) => priorities['$k'] = (v as num).toInt());

    return OverdueSummary(
      totalOverdue: (json['total_overdue'] as num?)?.toInt() ?? 0,
      agingBuckets: AgingBuckets.fromJson(Map<String, dynamic>.from(json['aging_buckets'] as Map? ?? {})),
      priorityBreakdown: priorities,
    );
  }
}

class AgingBuckets {
  final int bucket1To3;
  final int bucket4To7;
  final int bucket8To14;
  final int bucket15Plus;

  const AgingBuckets({
    this.bucket1To3 = 0,
    this.bucket4To7 = 0,
    this.bucket8To14 = 0,
    this.bucket15Plus = 0,
  });

  factory AgingBuckets.fromJson(Map<String, dynamic> json) {
    return AgingBuckets(
      bucket1To3: (json['1_to_3_days'] as num?)?.toInt() ?? 0,
      bucket4To7: (json['4_to_7_days'] as num?)?.toInt() ?? 0,
      bucket8To14: (json['8_to_14_days'] as num?)?.toInt() ?? 0,
      bucket15Plus: (json['15_plus_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class OverdueTaskItem {
  final int taskId;
  final String title;
  final String status;
  final String priority;
  final String? dueDate;
  final int daysOverdue;
  final String agingBucket;
  final double estimatedHours;
  final double actualHours;
  final int? projectId;
  final String? projectName;
  final String? projectCode;
  final int? assigneeId;
  final String assigneeName;
  final String? assigneeCode;

  const OverdueTaskItem({
    required this.taskId,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
    this.daysOverdue = 0,
    required this.agingBucket,
    this.estimatedHours = 0.0,
    this.actualHours = 0.0,
    this.projectId,
    this.projectName,
    this.projectCode,
    this.assigneeId,
    required this.assigneeName,
    this.assigneeCode,
  });

  factory OverdueTaskItem.fromJson(Map<String, dynamic> json) {
    return OverdueTaskItem(
      taskId: (json['task_id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] as String?,
      daysOverdue: (json['days_overdue'] as num?)?.toInt() ?? 0,
      agingBucket: json['aging_bucket'] as String? ?? '',
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0.0,
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0.0,
      projectId: (json['project_id'] as num?)?.toInt(),
      projectName: json['project_name'] as String?,
      projectCode: json['project_code'] as String?,
      assigneeId: (json['assignee_id'] as num?)?.toInt(),
      assigneeName: json['assignee_name'] as String? ?? 'Unassigned',
      assigneeCode: json['assignee_code'] as String?,
    );
  }
}

// -------------------------------------------------------------
// 6. Project Progress Models
// -------------------------------------------------------------

class ProjectProgressReport {
  final ProjectProgressSummary summary;
  final List<ProjectProgressItem> items;

  const ProjectProgressReport({
    required this.summary,
    required this.items,
  });

  factory ProjectProgressReport.fromJson(Map<String, dynamic> json) {
    return ProjectProgressReport(
      summary: ProjectProgressSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      items: (json['items'] as List? ?? [])
          .map((i) => ProjectProgressItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class ProjectProgressSummary {
  final int totalProjects;
  final int onTrackCount;
  final int dueSoonCount;
  final int overdueCount;
  final int completedCount;
  final double avgProgressPercent;

  const ProjectProgressSummary({
    this.totalProjects = 0,
    this.onTrackCount = 0,
    this.dueSoonCount = 0,
    this.overdueCount = 0,
    this.completedCount = 0,
    this.avgProgressPercent = 0.0,
  });

  factory ProjectProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProjectProgressSummary(
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      onTrackCount: (json['on_track_count'] as num?)?.toInt() ?? 0,
      dueSoonCount: (json['due_soon_count'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      avgProgressPercent: (json['avg_progress_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProjectProgressItem {
  final int projectId;
  final String name;
  final String? code;
  final String status;
  final String priority;
  final String? startDate;
  final String? deadline;
  final int? daysRemaining;
  final String health; // 'on_track', 'due_soon', 'overdue', 'completed'
  final String? departmentName;
  final String? teamLeadName;
  final String? managerName;
  final int membersCount;
  final int totalTasks;
  final int completedTasks;
  final double progressPercent;
  final double estimatedHours;
  final double actualHours;

  const ProjectProgressItem({
    required this.projectId,
    required this.name,
    this.code,
    required this.status,
    required this.priority,
    this.startDate,
    this.deadline,
    this.daysRemaining,
    required this.health,
    this.departmentName,
    this.teamLeadName,
    this.managerName,
    this.membersCount = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.progressPercent = 0.0,
    this.estimatedHours = 0.0,
    this.actualHours = 0.0,
  });

  factory ProjectProgressItem.fromJson(Map<String, dynamic> json) {
    return ProjectProgressItem(
      projectId: (json['project_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      status: json['status'] as String? ?? 'planned',
      priority: json['priority'] as String? ?? 'medium',
      startDate: json['start_date'] as String?,
      deadline: json['deadline'] as String?,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      health: json['health'] as String? ?? 'on_track',
      departmentName: json['department_name'] as String?,
      teamLeadName: json['team_lead_name'] as String?,
      managerName: json['manager_name'] as String?,
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0.0,
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// -------------------------------------------------------------
// 7. Team Performance Models
// -------------------------------------------------------------

class TeamPerformanceReport {
  final TeamPerformanceSummary summary;
  final List<TeamPerformanceItem> items;

  const TeamPerformanceReport({
    required this.summary,
    required this.items,
  });

  factory TeamPerformanceReport.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceReport(
      summary: TeamPerformanceSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      items: (json['items'] as List? ?? [])
          .map((i) => TeamPerformanceItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}

class TeamPerformanceSummary {
  final int totalMembers;
  final int totalTasksCompleted;
  final double avgOnTimeRate;
  final double totalHoursLogged;

  const TeamPerformanceSummary({
    this.totalMembers = 0,
    this.totalTasksCompleted = 0,
    this.avgOnTimeRate = 0.0,
    this.totalHoursLogged = 0.0,
  });

  factory TeamPerformanceSummary.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceSummary(
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      totalTasksCompleted: (json['total_tasks_completed'] as num?)?.toInt() ?? 0,
      avgOnTimeRate: (json['avg_on_time_rate'] as num?)?.toDouble() ?? 0.0,
      totalHoursLogged: (json['total_hours_logged'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TeamPerformanceItem {
  final int userId;
  final String name;
  final String email;
  final String? employeeCode;
  final String? departmentName;
  final String? designationName;
  final int assignedTasksCount;
  final int completedTasksCount;
  final int onTimeTasksCount;
  final int lateTasksCount;
  final double onTimeRatePercentage;
  final double firstTimeApprovalRate;
  final double totalLoggedHours;
  final double avgTaskDurationHours;

  const TeamPerformanceItem({
    required this.userId,
    required this.name,
    required this.email,
    this.employeeCode,
    this.departmentName,
    this.designationName,
    this.assignedTasksCount = 0,
    this.completedTasksCount = 0,
    this.onTimeTasksCount = 0,
    this.lateTasksCount = 0,
    this.onTimeRatePercentage = 0.0,
    this.firstTimeApprovalRate = 0.0,
    this.totalLoggedHours = 0.0,
    this.avgTaskDurationHours = 0.0,
  });

  factory TeamPerformanceItem.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceItem(
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
      departmentName: json['department_name'] as String?,
      designationName: json['designation_name'] as String?,
      assignedTasksCount: (json['assigned_tasks_count'] as num?)?.toInt() ?? 0,
      completedTasksCount: (json['completed_tasks_count'] as num?)?.toInt() ?? 0,
      onTimeTasksCount: (json['on_time_tasks_count'] as num?)?.toInt() ?? 0,
      lateTasksCount: (json['late_tasks_count'] as num?)?.toInt() ?? 0,
      onTimeRatePercentage: (json['on_time_rate_percentage'] as num?)?.toDouble() ?? 0.0,
      firstTimeApprovalRate: (json['first_time_approval_rate'] as num?)?.toDouble() ?? 0.0,
      totalLoggedHours: (json['total_logged_hours'] as num?)?.toDouble() ?? 0.0,
      avgTaskDurationHours: (json['avg_task_duration_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
