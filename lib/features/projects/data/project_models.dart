import 'package:flutter/material.dart';

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.clientName,
    this.status = 'planned',
    this.priority = 'medium',
    this.progress,
    this.taskMetricsAvailable = false,
    this.healthLabel = 'on_track',
    this.startDate,
    this.deadline,
    this.estimatedHours,
    this.budget,
    this.isOverdue = false,
    this.daysRemaining,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
    this.managerId,
    this.managerName,
    this.teamLeadId,
    this.teamLeadName,
    this.teamLeadEmail,
    this.teamLeadEmployeeCode,
    this.createdByName,
    this.membersCount = 0,
    this.totalTeamCount = 0,
    this.statusChangedAt,
    this.statusChangeReason,
    this.completionRequestedAt,
    this.completionRequestNotes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? code;
  final String? description;
  final String? clientName;
  final String status;
  final String priority;
  final int? progress;
  final bool taskMetricsAvailable;
  final String healthLabel;
  final String? startDate;
  final String? deadline;
  final double? estimatedHours;
  final double? budget;
  final bool isOverdue;
  final int? daysRemaining;

  final int? departmentId;
  final String? departmentName;
  final String? departmentCode;

  final int? managerId;
  final String? managerName;

  final int? teamLeadId;
  final String? teamLeadName;
  final String? teamLeadEmail;
  final String? teamLeadEmployeeCode;

  final String? createdByName;
  final int membersCount;
  final int totalTeamCount;

  final String? statusChangedAt;
  final String? statusChangeReason;
  final String? completionRequestedAt;
  final String? completionRequestNotes;

  final String? createdAt;
  final String? updatedAt;

  bool get isCompletionRequested => completionRequestedAt != null;
  bool get acceptsWork => !const ['on_hold', 'completed', 'archived', 'cancelled'].contains(status.toLowerCase());
  bool get isArchived => status.toLowerCase() == 'archived';

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return 'Active';
      case 'on_hold':
        return 'On Hold';
      case 'completed':
        return 'Completed';
      case 'archived':
        return 'Archived';
      case 'cancelled':
        return 'Cancelled';
      case 'planned':
      case 'planning':
      default:
        return 'Planned';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return const Color(0xFF2563EB); // blue
      case 'completed':
        return const Color(0xFF16A34A); // green
      case 'on_hold':
        return const Color(0xFFD97706); // amber
      case 'archived':
        return const Color(0xFF7C3AED); // purple
      case 'cancelled':
        return const Color(0xFFDC2626); // red
      case 'planned':
      case 'planning':
      default:
        return const Color(0xFF64748B); // slate
    }
  }

  String get healthLabelDisplay {
    switch (healthLabel.toLowerCase()) {
      case 'due_soon':
        return 'Due Soon';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Completed';
      case 'on_track':
      default:
        return 'On Track';
    }
  }

  Color get healthLabelColor {
    switch (healthLabel.toLowerCase()) {
      case 'due_soon':
        return const Color(0xFFD97706); // amber
      case 'overdue':
        return const Color(0xFFDC2626); // red
      case 'completed':
        return const Color(0xFF64748B); // slate
      case 'on_track':
      default:
        return const Color(0xFF16A34A); // green
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      case 'medium':
      default:
        return 'Medium';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFDC2626); // red
      case 'high':
        return const Color(0xFFEA580C); // orange
      case 'medium':
        return const Color(0xFF2563EB); // blue
      case 'low':
      default:
        return const Color(0xFF64748B); // slate
    }
  }

  String get deadlineDisplay {
    if (status == 'completed') return 'Completed';
    if (status == 'archived') return 'Archived';
    if (deadline == null) return 'No deadline';
    if (isOverdue) {
      final days = daysRemaining != null ? daysRemaining!.abs() : 0;
      return days == 0 ? 'Overdue today' : 'Overdue by $days d';
    }
    if (daysRemaining != null) {
      if (daysRemaining == 0) return 'Due today';
      if (daysRemaining == 1) return 'Due tomorrow';
      return '$daysRemaining days left';
    }
    return deadline!;
  }

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    final dept = json['department'] as Map<String, dynamic>?;
    final lead = json['team_lead'] as Map<String, dynamic>?;
    final mgr = json['manager'] as Map<String, dynamic>?;
    final creator = json['created_by'] as Map<String, dynamic>?;

    final rawCount = (json['members_count'] as num?)?.toInt() ?? 0;
    final totalCount = (json['total_team_count'] as num?)?.toInt() ??
        (rawCount + (json['team_lead_id'] != null ? 1 : 0));

    return ProjectItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      description: json['description'] as String?,
      clientName: json['client_name'] as String?,
      status: json['status'] as String? ?? 'planned',
      priority: json['priority'] as String? ?? 'medium',
      progress: (json['progress'] as num?)?.toInt(),
      taskMetricsAvailable: json['task_metrics_available'] as bool? ?? false,
      healthLabel: json['health_label'] as String? ?? 'on_track',
      startDate: json['start_date'] as String?,
      deadline: json['deadline'] as String?,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      budget: (json['budget'] as num?)?.toDouble(),
      isOverdue: json['is_overdue'] as bool? ?? false,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      departmentId: (dept?['id'] as num?)?.toInt() ?? (json['department_id'] as num?)?.toInt(),
      departmentName: dept?['name'] as String?,
      departmentCode: dept?['code'] as String?,
      managerId: (mgr?['id'] as num?)?.toInt() ?? (json['manager_id'] as num?)?.toInt(),
      managerName: mgr?['name'] as String?,
      teamLeadId: (lead?['id'] as num?)?.toInt() ?? (json['team_lead_id'] as num?)?.toInt(),
      teamLeadName: lead?['name'] as String?,
      teamLeadEmail: lead?['email'] as String?,
      teamLeadEmployeeCode: lead?['employee_code'] as String?,
      createdByName: creator?['name'] as String?,
      membersCount: rawCount,
      totalTeamCount: totalCount,
      statusChangedAt: json['status_changed_at'] as String?,
      statusChangeReason: json['status_change_reason'] as String?,
      completionRequestedAt: json['completion_requested_at'] as String?,
      completionRequestNotes: json['completion_request_notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class ProjectMemberItem {
  const ProjectMemberItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.employeeCode,
    this.projectRole = 'Member',
    this.assignedAt,
    this.departmentName,
    this.designationName,
    this.roleName,
  });

  final int id;
  final int userId;
  final String name;
  final String email;
  final String? employeeCode;
  final String projectRole;
  final String? assignedAt;
  final String? departmentName;
  final String? designationName;
  final String? roleName;

  factory ProjectMemberItem.fromJson(Map<String, dynamic> json) {
    final dept = json['department'] as Map<String, dynamic>?;
    final desig = json['designation'] as Map<String, dynamic>?;
    final role = json['role'] as Map<String, dynamic>?;

    return ProjectMemberItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
      projectRole: json['project_role'] as String? ?? 'Member',
      assignedAt: json['assigned_at'] as String?,
      departmentName: dept?['name'] as String?,
      designationName: desig?['name'] as String?,
      roleName: role?['name'] as String?,
    );
  }
}

class ProjectActivityItem {
  const ProjectActivityItem({
    required this.id,
    required this.action,
    required this.description,
    this.field,
    this.oldValue,
    this.newValue,
    this.reason,
    this.metadata,
    this.createdAt,
    this.userName,
    this.userEmail,
  });

  final int id;
  final String action;
  final String description;
  final String? field;
  final String? oldValue;
  final String? newValue;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final String? userName;
  final String? userEmail;

  factory ProjectActivityItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return ProjectActivityItem(
      id: (json['id'] as num).toInt(),
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
      field: json['field'] as String?,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      reason: json['reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
      userName: user?['name'] as String?,
      userEmail: user?['email'] as String?,
    );
  }
}

class ProjectDetail {
  const ProjectDetail({
    required this.project,
    this.members = const [],
    this.activities = const [],
  });

  final ProjectItem project;
  final List<ProjectMemberItem> members;
  final List<ProjectActivityItem> activities;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final project = ProjectItem.fromJson(json);

    final rawMembers = json['members'] as List<dynamic>? ?? [];
    final members = rawMembers
        .whereType<Map<String, dynamic>>()
        .map((m) => ProjectMemberItem.fromJson(m))
        .toList();

    final rawActivities = json['activities'] as List<dynamic>? ?? [];
    final activities = rawActivities
        .whereType<Map<String, dynamic>>()
        .map((a) => ProjectActivityItem.fromJson(a))
        .toList();

    return ProjectDetail(
      project: project,
      members: members,
      activities: activities,
    );
  }
}

class ProjectDashboardStats {
  const ProjectDashboardStats({
    this.totalProjects = 0,
    this.activeCount = 0,
    this.plannedCount = 0,
    this.inProgressCount = 0,
    this.planningCount = 0,
    this.onHoldCount = 0,
    this.completedCount = 0,
    this.archivedCount = 0,
    this.cancelledCount = 0,
    this.overdueCount = 0,
    this.priorityBreakdown = const {},
    this.upcomingDeadlines = const [],
    this.recentProjects = const [],
  });

  final int totalProjects;
  final int activeCount;
  final int plannedCount;
  final int inProgressCount;
  final int planningCount;
  final int onHoldCount;
  final int completedCount;
  final int archivedCount;
  final int cancelledCount;
  final int overdueCount;
  final Map<String, int> priorityBreakdown;
  final List<ProjectItem> upcomingDeadlines;
  final List<ProjectItem> recentProjects;

  factory ProjectDashboardStats.fromJson(Map<String, dynamic> json) {
    final pMap = <String, int>{};
    final rawP = json['priority_breakdown'];
    if (rawP is Map) {
      rawP.forEach((k, v) => pMap['$k'] = (v as num?)?.toInt() ?? 0);
    }

    final rawUpcoming = json['upcoming_deadlines'] as List<dynamic>? ?? [];
    final upcoming = rawUpcoming
        .whereType<Map<String, dynamic>>()
        .map((p) => ProjectItem.fromJson(p))
        .toList();

    final rawRecent = json['recent_projects'] as List<dynamic>? ?? [];
    final recent = rawRecent
        .whereType<Map<String, dynamic>>()
        .map((p) => ProjectItem.fromJson(p))
        .toList();

    final actCount = (json['active_count'] as num?)?.toInt() ?? (json['in_progress_count'] as num?)?.toInt() ?? 0;
    final planCount = (json['planned_count'] as num?)?.toInt() ?? (json['planning_count'] as num?)?.toInt() ?? 0;

    return ProjectDashboardStats(
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      activeCount: actCount,
      plannedCount: planCount,
      inProgressCount: actCount,
      planningCount: planCount,
      onHoldCount: (json['on_hold_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      archivedCount: (json['archived_count'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelled_count'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      priorityBreakdown: pMap,
      upcomingDeadlines: upcoming,
      recentProjects: recent,
    );
  }
}

class PaginatedProjects {
  const PaginatedProjects({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  final List<ProjectItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  bool get hasMore => currentPage < lastPage;

  factory PaginatedProjects.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final rawData = json['data'] as List<dynamic>? ?? [];

    final items = rawData
        .whereType<Map<String, dynamic>>()
        .map((item) => ProjectItem.fromJson(item))
        .toList();

    return PaginatedProjects(
      items: items,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      perPage: (meta['per_page'] as num?)?.toInt() ?? 15,
    );
  }
}

class AddMemberResult {
  const AddMemberResult({
    required this.detail,
    this.warnings = const [],
  });

  final ProjectDetail detail;
  final List<String> warnings;

  factory AddMemberResult.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'] != null
        ? ProjectDetail.fromJson(json['detail'] as Map<String, dynamic>)
        : (json['project'] != null
            ? ProjectDetail.fromJson(json)
            : ProjectDetail(project: ProjectItem.fromJson(json)));
    final warnings = (json['warnings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return AddMemberResult(detail: detail, warnings: warnings);
  }
}

