import 'package:flutter/material.dart';
import '../../projects/data/project_models.dart';

/// Task Status constants and transitions
class TaskStatus {
  TaskStatus._();

  static const String backlog = 'backlog';
  static const String assigned = 'assigned';
  static const String inProgress = 'in_progress';
  static const String review = 'review';
  static const String changesRequired = 'changes_required';
  static const String completed = 'completed';

  static const List<String> all = [
    backlog,
    assigned,
    inProgress,
    review,
    changesRequired,
    completed,
  ];

  static const Map<String, List<String>> allowedTransitions = {
    backlog: [assigned, inProgress],
    assigned: [inProgress, backlog],
    inProgress: [review, assigned],
    review: [changesRequired, completed],
    changesRequired: [inProgress],
    completed: [inProgress], // reopen
  };

  /// Returns transitions allowed for the specific actor role on this task.
  static List<String> allowedTransitionsFor({
    required String currentStatus,
    required bool isAssignee,
    required bool canManage,
  }) {
    final all = allowedTransitions[currentStatus] ?? [];
    return all.where((target) {
      if (currentStatus == inProgress) {
        if (target == review) return isAssignee || canManage;
        if (target == assigned) return canManage;
      }
      if (currentStatus == review) {
        if (!canManage) return false;
        // Assignee cannot approve their own work
        if (target == completed && isAssignee) return false;
        return true;
      }
      if (currentStatus == completed) {
        return canManage;
      }
      if (currentStatus == changesRequired) {
        return isAssignee || canManage;
      }
      return isAssignee || canManage;
    }).toList();
  }

  static String label(String status) {
    switch (status.toLowerCase()) {
      case backlog:
        return 'Backlog';
      case assigned:
        return 'Assigned';
      case inProgress:
        return 'In Progress';
      case review:
        return 'In Review';
      case changesRequired:
        return 'Changes Req.';
      case completed:
        return 'Completed';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status.toLowerCase()) {
      case backlog:
        return const Color(0xFF64748B); // Slate
      case assigned:
        return const Color(0xFF0284C7); // Sky / Blue
      case inProgress:
        return const Color(0xFF2563EB); // Royal Blue
      case review:
        return const Color(0xFF8B5CF6); // Purple
      case changesRequired:
        return const Color(0xFFD97706); // Amber
      case completed:
        return const Color(0xFF10B981); // Emerald / Green
      default:
        return const Color(0xFF64748B);
    }
  }

  static IconData icon(String status) {
    switch (status.toLowerCase()) {
      case backlog:
        return Icons.inbox_outlined;
      case assigned:
        return Icons.assignment_ind_outlined;
      case inProgress:
        return Icons.play_circle_outline;
      case review:
        return Icons.rate_review_outlined;
      case changesRequired:
        return Icons.published_with_changes;
      case completed:
        return Icons.check_circle_outline;
      default:
        return Icons.task_alt;
    }
  }
}

/// Deadline Variance constants
class DeadlineVariance {
  DeadlineVariance._();

  static const String completedEarly = 'completed_early';
  static const String completedOnTime = 'completed_on_time';
  static const String completedLate = 'completed_late';
  static const String onTrack = 'on_track';
  static const String overdue = 'overdue';

  static String label(String? variance) {
    switch (variance) {
      case completedEarly:
        return 'Completed Early';
      case completedOnTime:
        return 'Completed On Time';
      case completedLate:
        return 'Completed Late';
      case overdue:
        return 'Overdue';
      case onTrack:
      default:
        return 'On Track';
    }
  }

  static Color color(String? variance) {
    switch (variance) {
      case completedEarly:
      case completedOnTime:
        return const Color(0xFF10B981); // Emerald
      case onTrack:
        return const Color(0xFF0284C7); // Sky
      case completedLate:
      case overdue:
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }
}

/// Task Priority constants
class TaskPriority {
  TaskPriority._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';

  static const List<String> all = [low, medium, high, urgent];

  static String label(String priority) {
    switch (priority.toLowerCase()) {
      case urgent:
        return 'Urgent';
      case high:
        return 'High';
      case low:
        return 'Low';
      case medium:
      default:
        return 'Medium';
    }
  }

  static Color color(String priority) {
    switch (priority.toLowerCase()) {
      case urgent:
        return const Color(0xFFDC2626); // Red
      case high:
        return const Color(0xFFEA580C); // Orange
      case medium:
        return const Color(0xFF2563EB); // Blue
      case low:
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}

/// Task Model representing a single task or subtask
class TaskItem {
  const TaskItem({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.title,
    this.parentTaskId,
    this.description,
    this.status = TaskStatus.backlog,
    this.priority = TaskPriority.medium,
    this.position = 0,
    this.dueDate,
    this.isOverdue = false,
    this.daysRemaining,
    this.estimatedHours,
    this.actualHours = 0.0,
    this.timeVariance,
    this.deadlineVariance,
    this.startedAt,
    this.completedAt,
    this.assignedTo,
    this.createdBy,
    this.subtasksCount = 0,
    this.hasActiveTimer = false,
    this.activeTimer,
    this.projectName,
    this.submittedById,
    this.submittedByName,
    this.submittedAt,
    this.waitingTimeHuman,
    this.reviewerId,
    this.latestReview,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int companyId;
  final int projectId;
  final int? parentTaskId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final int position;
  final String? dueDate;
  final bool isOverdue;
  final int? daysRemaining;
  final double? estimatedHours;
  final double actualHours;
  final String? timeVariance;
  final String? deadlineVariance;
  final String? startedAt;
  final String? completedAt;
  final TaskUserItem? assignedTo;
  final TaskUserItem? createdBy;
  final int subtasksCount;
  final bool hasActiveTimer;
  final ActiveTimerInfo? activeTimer;
  final String? projectName;
  final int? submittedById;
  final String? submittedByName;
  final String? submittedAt;
  final String? waitingTimeHuman;
  final int? reviewerId;
  final TaskReviewInfo? latestReview;
  final String? createdAt;
  final String? updatedAt;

  String? get assignedToName => assignedTo?.name;

  bool get isSubtask => parentTaskId != null;
  bool get isCompleted => status == TaskStatus.completed;

  String get statusDisplay => TaskStatus.label(status);
  Color get statusColor => TaskStatus.color(status);
  IconData get statusIcon => TaskStatus.icon(status);

  String get priorityDisplay => TaskPriority.label(priority);
  Color get priorityColor => TaskPriority.color(priority);

  String get timeVarianceDisplay {
    if (timeVariance == 'early') return 'Under Est.';
    if (timeVariance == 'on_time') return 'On Time';
    if (timeVariance == 'over_time') return 'Over Est.';
    return 'Pending';
  }

  Color get timeVarianceColor {
    if (timeVariance == 'early') return const Color(0xFF10B981);
    if (timeVariance == 'on_time') return const Color(0xFF0284C7);
    if (timeVariance == 'over_time') return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  String get deadlineDisplay {
    if (isCompleted) return 'Completed';
    if (dueDate == null) return 'No due date';
    if (isOverdue) {
      final days = daysRemaining != null ? daysRemaining!.abs() : 0;
      return days == 0 ? 'Due today' : 'Overdue by $days d';
    }
    if (daysRemaining != null) {
      if (daysRemaining == 0) return 'Due today';
      if (daysRemaining == 1) return 'Due tomorrow';
      return '$daysRemaining days left';
    }
    return dueDate!;
  }

  bool get isDueToday => !isCompleted && dueDate != null && daysRemaining == 0;
  bool get isDueSoon => !isCompleted && dueDate != null && daysRemaining != null && daysRemaining! > 0 && daysRemaining! <= 2;

  String get deadlineVarianceDisplay => DeadlineVariance.label(deadlineVariance);
  Color get deadlineVarianceColor => DeadlineVariance.color(deadlineVariance);

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final assigned = json['assigned_to'] as Map<String, dynamic>?;
    final created = json['created_by'] as Map<String, dynamic>?;
    final submitted = json['submitted_by'] as Map<String, dynamic>?;
    final reviewJson = json['latest_review'] as Map<String, dynamic>?;
    final timerJson = json['active_timer'] as Map<String, dynamic>?;

    return TaskItem(
      id: (json['id'] as num).toInt(),
      companyId: (json['company_id'] as num?)?.toInt() ?? 0,
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      parentTaskId: (json['parent_task_id'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? TaskStatus.backlog,
      priority: json['priority'] as String? ?? TaskPriority.medium,
      position: (json['position'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] as String?,
      isOverdue: json['is_overdue'] as bool? ?? false,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0.0,
      timeVariance: json['time_variance'] as String?,
      deadlineVariance: json['deadline_variance'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      assignedTo: assigned != null ? TaskUserItem.fromJson(assigned) : null,
      createdBy: created != null ? TaskUserItem.fromJson(created) : null,
      subtasksCount: (json['subtasks_count'] as num?)?.toInt() ?? 0,
      hasActiveTimer: json['has_active_timer'] as bool? ?? false,
      activeTimer: timerJson != null ? ActiveTimerInfo.fromJson(timerJson) : null,
      projectName: (json['project'] as Map<String, dynamic>?)?['name'] as String? ?? json['project_name'] as String?,
      submittedById: (json['submitted_by_id'] as num?)?.toInt(),
      submittedByName: submitted != null ? (submitted['name'] as String?) : null,
      submittedAt: json['submitted_at'] as String?,
      waitingTimeHuman: json['waiting_time_human'] as String?,
      reviewerId: (json['reviewer_id'] as num?)?.toInt(),
      latestReview: reviewJson != null ? TaskReviewInfo.fromJson(reviewJson) : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

/// Review outcome and round information for review workflow
class TaskReviewInfo {
  const TaskReviewInfo({
    required this.id,
    required this.roundNumber,
    this.outcome,
    this.feedback,
    this.reviewerId,
    this.reviewerName,
    this.decidedAt,
  });

  final int id;
  final int roundNumber;
  final String? outcome;
  final String? feedback;
  final int? reviewerId;
  final String? reviewerName;
  final String? decidedAt;

  factory TaskReviewInfo.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    return TaskReviewInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      outcome: json['outcome'] as String?,
      feedback: json['feedback'] as String?,
      reviewerId: (json['reviewer_id'] as num?)?.toInt(),
      reviewerName: reviewer != null ? reviewer['name'] as String? : null,
      decidedAt: json['decided_at'] as String?,
    );
  }
}

/// Detailed Task with relations
class TaskDetail {
  const TaskDetail({
    required this.task,
    this.project,
    this.parentTask,
    this.subtasks = const [],
    this.timeEntries = const [],
    this.activities = const [],
  });

  final TaskItem task;
  final TaskProjectRef? project;
  final TaskParentRef? parentTask;
  final List<TaskItem> subtasks;
  final List<TimeEntryItem> timeEntries;
  final List<ProjectActivityItem> activities;

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    final taskItem = TaskItem.fromJson(json);
    final pJson = json['project'] as Map<String, dynamic>?;
    final parentJson = json['parent_task'] as Map<String, dynamic>?;

    final rawSubtasks = json['subtasks'] as List<dynamic>? ?? [];
    final subtasks = rawSubtasks
        .whereType<Map<String, dynamic>>()
        .map((s) => TaskItem.fromJson(s))
        .toList();

    final rawTimeEntries = json['time_entries'] as List<dynamic>? ?? [];
    final timeEntries = rawTimeEntries
        .whereType<Map<String, dynamic>>()
        .map((te) => TimeEntryItem.fromJson(te))
        .toList();

    final rawActivities = json['activities'] as List<dynamic>? ?? [];
    final activities = rawActivities
        .whereType<Map<String, dynamic>>()
        .map((a) => ProjectActivityItem.fromJson(a))
        .toList();

    return TaskDetail(
      task: taskItem,
      project: pJson != null ? TaskProjectRef.fromJson(pJson) : null,
      parentTask: parentJson != null ? TaskParentRef.fromJson(parentJson) : null,
      subtasks: subtasks,
      timeEntries: timeEntries,
      activities: activities,
    );
  }
}

/// Project Reference in Task Details
class TaskProjectRef {
  const TaskProjectRef({
    required this.id,
    required this.name,
    this.code,
    this.status = 'active',
    this.acceptsWork = true,
    this.managerId,
    this.teamLeadId,
  });

  final int id;
  final String name;
  final String? code;
  final String status;
  final bool acceptsWork;
  final int? managerId;
  final int? teamLeadId;

  factory TaskProjectRef.fromJson(Map<String, dynamic> json) {
    return TaskProjectRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      status: json['status'] as String? ?? 'active',
      acceptsWork: json['accepts_work'] as bool? ?? true,
      managerId: (json['manager_id'] as num?)?.toInt(),
      teamLeadId: (json['team_lead_id'] as num?)?.toInt(),
    );
  }
}

/// Parent Task Reference
class TaskParentRef {
  const TaskParentRef({
    required this.id,
    required this.title,
    this.status = 'backlog',
  });

  final int id;
  final String title;
  final String status;

  factory TaskParentRef.fromJson(Map<String, dynamic> json) {
    return TaskParentRef(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'backlog',
    );
  }
}

/// User Reference in Task & Time Entries
class TaskUserItem {
  const TaskUserItem({
    required this.id,
    required this.name,
    this.email,
    this.employeeCode,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? email;
  final String? employeeCode;
  final String? avatarUrl;

  factory TaskUserItem.fromJson(Map<String, dynamic> json) {
    return TaskUserItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      employeeCode: json['employee_code'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Active Timer information attached to Task
class ActiveTimerInfo {
  const ActiveTimerInfo({
    required this.id,
    this.startedAt,
    this.durationSeconds = 0,
    this.isPaused = false,
    this.pausedAt,
  });

  final int id;
  final String? startedAt;
  final int durationSeconds;
  final bool isPaused;
  final String? pausedAt;

  factory ActiveTimerInfo.fromJson(Map<String, dynamic> json) {
    return ActiveTimerInfo(
      id: (json['id'] as num).toInt(),
      startedAt: json['started_at'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      isPaused: json['is_paused'] as bool? ?? false,
      pausedAt: json['paused_at'] as String?,
    );
  }
}

/// Time Tracking Entry Model
class TimeEntryItem {
  const TimeEntryItem({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.taskId,
    required this.userId,
    this.projectName,
    this.taskTitle,
    this.user,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.durationHours = 0.0,
    this.description,
    this.isManual = false,
    this.isRunning = false,
    this.isPaused = false,
    this.pausedAt,
    this.isAutoStopped = false,
    this.createdAt,
  });

  final int id;
  final int companyId;
  final int projectId;
  final int taskId;
  final int userId;
  final String? projectName;
  final String? taskTitle;
  final TaskUserItem? user;
  final String? startedAt;
  final String? endedAt;
  final int durationSeconds;
  final double durationHours;
  final String? description;
  final bool isManual;
  final bool isRunning;
  final bool isPaused;
  final String? pausedAt;
  final bool isAutoStopped;
  final String? createdAt;

  String get durationFormatted {
    final hours = durationSeconds ~/ 3600;
    final mins = (durationSeconds % 3600) ~/ 60;
    final secs = durationSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  factory TimeEntryItem.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;

    return TimeEntryItem(
      id: (json['id'] as num).toInt(),
      companyId: (json['company_id'] as num?)?.toInt() ?? 0,
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      taskId: (json['task_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      projectName: json['project_name'] as String?,
      taskTitle: json['task_title'] as String?,
      user: userJson != null ? TaskUserItem.fromJson(userJson) : null,
      startedAt: json['started_at'] as String?,
      endedAt: json['ended_at'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      isManual: json['is_manual'] as bool? ?? false,
      isRunning: json['is_running'] as bool? ?? false,
      isPaused: json['is_paused'] as bool? ?? false,
      pausedAt: json['paused_at'] as String?,
      isAutoStopped: json['is_auto_stopped'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

/// Aggregated Task Metrics for Project Overview
class TaskMetrics {
  const TaskMetrics({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.inProgressTasks = 0,
    this.reviewTasks = 0,
    this.backlogTasks = 0,
    this.overdueTasks = 0,
    this.progressPercentage = 0,
    this.estimatedHoursTotal = 0.0,
    this.actualHoursTotal = 0.0,
  });

  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int reviewTasks;
  final int backlogTasks;
  final int overdueTasks;
  final int progressPercentage;
  final double estimatedHoursTotal;
  final double actualHoursTotal;

  double get progressRatio => totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

  factory TaskMetrics.fromJson(Map<String, dynamic> json) {
    return TaskMetrics(
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      inProgressTasks: (json['in_progress_tasks'] as num?)?.toInt() ?? 0,
      reviewTasks: (json['review_tasks'] as num?)?.toInt() ?? 0,
      backlogTasks: (json['backlog_tasks'] as num?)?.toInt() ?? 0,
      overdueTasks: (json['overdue_tasks'] as num?)?.toInt() ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      estimatedHoursTotal: (json['estimated_hours_total'] as num?)?.toDouble() ?? 0.0,
      actualHoursTotal: (json['actual_hours_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// My Work Today Summary Model
class MyWorkTodaySummary {
  const MyWorkTodaySummary({
    this.dueTodayTasks = const [],
    this.overdueTasks = const [],
    this.inProgressTasks = const [],
    this.hoursLoggedToday = 0.0,
    this.activeTimer,
  });

  final List<TaskItem> dueTodayTasks;
  final List<TaskItem> overdueTasks;
  final List<TaskItem> inProgressTasks;
  final double hoursLoggedToday;
  final TimeEntryItem? activeTimer;

  factory MyWorkTodaySummary.fromJson(Map<String, dynamic> json) {
    final rawDue = json['due_today_tasks'] as List<dynamic>? ?? [];
    final rawOverdue = json['overdue_tasks'] as List<dynamic>? ?? [];
    final rawInProgress = json['in_progress_tasks'] as List<dynamic>? ?? [];
    final timerJson = json['active_timer'] as Map<String, dynamic>?;

    return MyWorkTodaySummary(
      dueTodayTasks: rawDue.whereType<Map<String, dynamic>>().map((t) => TaskItem.fromJson(t)).toList(),
      overdueTasks: rawOverdue.whereType<Map<String, dynamic>>().map((t) => TaskItem.fromJson(t)).toList(),
      inProgressTasks: rawInProgress.whereType<Map<String, dynamic>>().map((t) => TaskItem.fromJson(t)).toList(),
      hoursLoggedToday: (json['hours_logged_today'] as num?)?.toDouble() ?? 0.0,
      activeTimer: timerJson != null ? TimeEntryItem.fromJson(timerJson) : null,
    );
  }
}

/// Timesheet Data Model
class TimesheetData {
  const TimesheetData({
    this.userId,
    this.dateFrom,
    this.dateTo,
    this.totalHours = 0.0,
    this.totalSeconds = 0,
    this.days = const [],
  });

  final int? userId;
  final String? dateFrom;
  final String? dateTo;
  final double totalHours;
  final int totalSeconds;
  final List<TimesheetDayItem> days;

  factory TimesheetData.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    return TimesheetData(
      userId: (json['user_id'] as num?)?.toInt(),
      dateFrom: json['date_from'] as String?,
      dateTo: json['date_to'] as String?,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalSeconds: (json['total_seconds'] as num?)?.toInt() ?? 0,
      days: rawDays.whereType<Map<String, dynamic>>().map((d) => TimesheetDayItem.fromJson(d)).toList(),
    );
  }
}

class TimesheetDayItem {
  const TimesheetDayItem({
    required this.date,
    required this.dayName,
    this.hours = 0.0,
    this.seconds = 0,
    this.entriesCount = 0,
    this.tasks = const [],
  });

  final String date;
  final String dayName;
  final double hours;
  final int seconds;
  final int entriesCount;
  final List<TimesheetDayTaskItem> tasks;

  factory TimesheetDayItem.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return TimesheetDayItem(
      date: json['date'] as String? ?? '',
      dayName: json['day_name'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
      entriesCount: (json['entries_count'] as num?)?.toInt() ?? 0,
      tasks: rawTasks.whereType<Map<String, dynamic>>().map((t) => TimesheetDayTaskItem.fromJson(t)).toList(),
    );
  }
}

class TimesheetDayTaskItem {
  const TimesheetDayTaskItem({
    required this.taskId,
    this.taskTitle,
    this.projectName,
    this.durationHours = 0.0,
    this.isManual = false,
  });

  final int taskId;
  final String? taskTitle;
  final String? projectName;
  final double durationHours;
  final bool isManual;

  factory TimesheetDayTaskItem.fromJson(Map<String, dynamic> json) {
    return TimesheetDayTaskItem(
      taskId: (json['task_id'] as num?)?.toInt() ?? 0,
      taskTitle: json['task_title'] as String?,
      projectName: json['project_name'] as String?,
      durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 0.0,
      isManual: json['is_manual'] as bool? ?? false,
    );
  }
}

class TeamTimesheetData {
  const TeamTimesheetData({
    this.dateFrom,
    this.dateTo,
    this.totalHours = 0.0,
    this.members = const [],
  });

  final String? dateFrom;
  final String? dateTo;
  final double totalHours;
  final List<TeamTimesheetMember> members;

  factory TeamTimesheetData.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    return TeamTimesheetData(
      dateFrom: json['date_from'] as String?,
      dateTo: json['date_to'] as String?,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      members: rawMembers.whereType<Map<String, dynamic>>().map((m) => TeamTimesheetMember.fromJson(m)).toList(),
    );
  }
}

class TeamTimesheetMember {
  const TeamTimesheetMember({
    this.user,
    this.totalHours = 0.0,
    this.totalSeconds = 0,
    this.entriesCount = 0,
  });

  final TaskUserItem? user;
  final double totalHours;
  final int totalSeconds;
  final int entriesCount;

  factory TeamTimesheetMember.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return TeamTimesheetMember(
      user: userJson != null ? TaskUserItem.fromJson(userJson) : null,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalSeconds: (json['total_seconds'] as num?)?.toInt() ?? 0,
      entriesCount: (json['entries_count'] as num?)?.toInt() ?? 0,
    );
  }
}
