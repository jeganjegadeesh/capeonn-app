class OfficeLocation {
  const OfficeLocation({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 500,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.userId,
    this.userName,
    this.employeeCode,
    this.departmentName,
    required this.date,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLocationName,
    required this.isFlagged,
    this.flaggedReason,
    required this.geofenceStatus,
    required this.status,
    required this.totalMinutes,
    required this.totalHoursFormatted,
    this.notes,
  });

  final int id;
  final int userId;
  final String? userName;
  final String? employeeCode;
  final String? departmentName;
  final String date;
  final String? clockInAt;
  final String? clockOutAt;
  final String? clockInLocationName;
  final bool isFlagged;
  final String? flaggedReason;
  final String geofenceStatus; // inside, outside, unknown
  final String status; // present, late, half_day, absent, on_leave
  final int totalMinutes;
  final String totalHoursFormatted;
  final String? notes;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: json['user_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      departmentName: json['department_name'] as String?,
      date: json['date'] as String,
      clockInAt: json['clock_in_at'] as String?,
      clockOutAt: json['clock_out_at'] as String?,
      clockInLocationName: json['clock_in_location_name'] as String?,
      isFlagged: json['is_flagged'] as bool? ?? false,
      flaggedReason: json['flagged_reason'] as String?,
      geofenceStatus: json['geofence_status'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'present',
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      totalHoursFormatted: json['total_hours_formatted'] as String? ?? '0h 00m',
      notes: json['notes'] as String?,
    );
  }
}

class AttendanceToday {
  const AttendanceToday({
    required this.date,
    this.attendance,
    required this.isClockedIn,
    required this.isClockedOut,
    this.isApplicable = true,
    required this.elapsedSeconds,
    this.officeLocations = const [],
  });

  final String date;
  final AttendanceRecord? attendance;
  final bool isClockedIn;
  final bool isClockedOut;
  final bool isApplicable;
  final int elapsedSeconds;
  final List<OfficeLocation> officeLocations;

  factory AttendanceToday.fromJson(Map<String, dynamic> json) {
    final attRaw = json['attendance'];
    final locsRaw = json['office_locations'] as List? ?? [];

    return AttendanceToday(
      date: json['date'] as String,
      attendance: attRaw is Map<String, dynamic> ? AttendanceRecord.fromJson(attRaw) : null,
      isClockedIn: json['is_clocked_in'] as bool? ?? false,
      isClockedOut: json['is_clocked_out'] as bool? ?? false,
      isApplicable: json['is_applicable'] as bool? ?? true,
      elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
      officeLocations: locsRaw
          .whereType<Map<String, dynamic>>()
          .map(OfficeLocation.fromJson)
          .toList(),
    );
  }
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.year,
    required this.month,
    required this.daysPresent,
    required this.daysLate,
    required this.daysHalfDay,
    required this.totalHours,
    required this.totalRecords,
  });

  final int year;
  final int month;
  final int daysPresent;
  final int daysLate;
  final int daysHalfDay;
  final double totalHours;
  final int totalRecords;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      daysPresent: (json['days_present'] as num?)?.toInt() ?? 0,
      daysLate: (json['days_late'] as num?)?.toInt() ?? 0,
      daysHalfDay: (json['days_half_day'] as num?)?.toInt() ?? 0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceRegularization {
  const AttendanceRegularization({
    required this.id,
    this.attendanceId,
    required this.userId,
    this.userName,
    this.employeeCode,
    required this.date,
    required this.requestedClockIn,
    required this.requestedClockOut,
    required this.reason,
    required this.status,
    this.rejectionReason,
    this.actionedBy,
    required this.createdAt,
  });

  final int id;
  final int? attendanceId;
  final int userId;
  final String? userName;
  final String? employeeCode;
  final String date;
  final String requestedClockIn;
  final String requestedClockOut;
  final String reason;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final Map<String, dynamic>? actionedBy;
  final String createdAt;

  factory AttendanceRegularization.fromJson(Map<String, dynamic> json) {
    return AttendanceRegularization(
      id: (json['id'] as num).toInt(),
      attendanceId: (json['attendance_id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: json['user_name'] as String?,
      employeeCode: json['employee_code'] as String?,
      date: json['date'] as String,
      requestedClockIn: json['requested_clock_in'] as String,
      requestedClockOut: json['requested_clock_out'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      actionedBy: json['actioned_by'] is Map<String, dynamic> ? json['actioned_by'] as Map<String, dynamic> : null,
      createdAt: json['created_at'] as String,
    );
  }
}
