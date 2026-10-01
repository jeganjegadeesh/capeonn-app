class LeaveType {
  const LeaveType({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.annualDays,
    required this.isPaid,
  });

  final int id;
  final String name;
  final String code;
  final String? description;
  final double annualDays;
  final bool isPaid;

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      annualDays: (json['annual_days'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['is_paid'] as bool? ?? true,
    );
  }
}

class LeaveBalance {
  const LeaveBalance({
    required this.id,
    required this.leaveTypeId,
    required this.name,
    required this.code,
    required this.isPaid,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.pendingDays,
    required this.remainingDays,
  });

  final int id;
  final int leaveTypeId;
  final String name;
  final String code;
  final bool isPaid;
  final int year;
  final double totalDays;
  final double usedDays;
  final double pendingDays;
  final double remainingDays;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: (json['id'] as num).toInt(),
      leaveTypeId: (json['leave_type_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      isPaid: json['is_paid'] as bool? ?? true,
      year: (json['year'] as num).toInt(),
      totalDays: (json['total_days'] as num?)?.toDouble() ?? 0.0,
      usedDays: (json['used_days'] as num?)?.toDouble() ?? 0.0,
      pendingDays: (json['pending_days'] as num?)?.toDouble() ?? 0.0,
      remainingDays: (json['remaining_days'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LeaveRequestItem {
  const LeaveRequestItem({
    required this.id,
    required this.userId,
    this.userName,
    this.employeeCode,
    this.departmentName,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.leaveTypeCode,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    this.halfDayType,
    required this.daysCount,
    required this.reason,
    required this.status, // pending, approved, rejected, cancelled
    this.actionRemarks,
    this.actionedBy,
    this.approverId,
    this.approverName,
    this.finalApprover = false,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String? userName;
  final String? employeeCode;
  final String? departmentName;
  final int leaveTypeId;
  final String leaveTypeName;
  final String leaveTypeCode;
  final String startDate;
  final String endDate;
  final bool isHalfDay;
  final String? halfDayType;
  final double daysCount;
  final String reason;
  final String status;
  final String? actionRemarks;
  final Map<String, dynamic>? actionedBy;
  final int? approverId;
  final String? approverName;
  final bool finalApprover;
  final String createdAt;

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) {
    return LeaveRequestItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: json['user_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      departmentName: json['department_name'] as String?,
      leaveTypeId: (json['leave_type_id'] as num).toInt(),
      leaveTypeName: json['leave_type_name'] as String? ?? '',
      leaveTypeCode: json['leave_type_code'] as String? ?? '',
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      isHalfDay: json['is_half_day'] as bool? ?? false,
      halfDayType: json['half_day_type'] as String?,
      daysCount: (json['days_count'] as num?)?.toDouble() ?? 1.0,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      actionRemarks: json['action_remarks'] as String?,
      actionedBy: json['actioned_by'] is Map ? Map<String, dynamic>.from(json['actioned_by'] as Map) : null,
      approverId: (json['approver_id'] as num?)?.toInt(),
      approverName: json['approver_name'] as String?,
      finalApprover: json['final_approver'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }
}
