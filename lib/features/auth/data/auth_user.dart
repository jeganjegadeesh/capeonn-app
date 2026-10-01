/// The signed-in user, as returned by /auth/login and /auth/me.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleSlug,
    required this.roleName,
    required this.roleLevel,
    this.phone,
    this.employeeCode,
    this.isActive = true,
    this.isAttendanceApplicable = true,
    this.salary,
    this.companyName,
    this.departmentName,
    this.designationName,
    this.reportsToName,
    this.dob,
    this.gender,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.employmentType,
    this.probationEndDate,
    this.skills = const [],
    this.certifications = const [],
    this.permissions = const {},
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? employeeCode;
  final bool isActive;
  final bool isAttendanceApplicable;
  final double? salary;

  final String roleSlug; // super_admin | admin | hr | manager | team_lead | employee
  final String roleName;
  final int roleLevel;

  final String? companyName;
  final String? departmentName;
  final String? designationName;
  final String? reportsToName;

  final String? dob;
  final String? gender;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? employmentType;
  final String? probationEndDate;
  final List<String> skills;
  final List<Map<String, dynamic>> certifications;

  /// permission slug -> scope (all | department | team | assigned | self)
  final Map<String, String> permissions;

  bool get isAdmin => roleSlug == 'admin' || roleSlug == 'super_admin';
  bool get isSuperAdmin => roleSlug == 'super_admin' || roleSlug == 'admin';
  bool get isHR => roleSlug == 'hr';
  bool get isManager => roleSlug == 'manager';
  bool get isTeamLead => roleSlug == 'team_lead';
  bool get isEmployee => roleSlug == 'employee';

  /// Attendance and leaves are hidden for Super Admin accounts
  bool get canAccessAttendance => isAttendanceApplicable && !isSuperAdmin;
  bool get canAccessLeaves => !isSuperAdmin;

  /// Use this to show/hide screens and buttons. The server enforces the same rules anyway.
  bool can(String permission) => permissions.containsKey(permission);

  String? scopeOf(String permission) => permissions[permission];

  bool get canViewOrganization => can('organization.view');
  bool get canManageOrganization => can('organization.manage');
  bool get canManageRoles => can('roles.manage');
  bool get canManageSystem => can('system.manage');
  bool get canViewEmployees => can('employees.view');
  bool get canManageEmployees => can('employees.manage');
  bool get canViewHierarchy => can('employees.view');

  bool get canViewAttendance => canAccessAttendance && can('attendance.view');
  bool get canRecordAttendance => canAccessAttendance && can('attendance.record');
  bool get canManageAttendance => can('attendance.manage');

  bool get canViewLeaves => canAccessLeaves && can('leave.view');
  bool get canApplyLeave => canAccessLeaves && can('leave.apply');
  bool get canApproveLeave => can('leave.approve');
  bool get canManageLeaves => can('leave.manage');

  bool get canViewHolidays => can('holidays.view');
  bool get canManageHolidays => can('holidays.manage');

  bool get canViewDocuments => can('documents.view');
  bool get canManageDocuments => can('documents.manage');
  bool get canVerifyDocuments => can('documents.verify');

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    String? nameOf(dynamic value) => value is Map ? value['name'] as String? : null;

    final role = json['role'] is Map ? json['role'] as Map : const {};
    final permissions = <String, String>{};
    final rawPermissions = json['permissions'];
    if (rawPermissions is Map) {
      rawPermissions.forEach((key, value) => permissions['$key'] = '$value');
    }

    final rawSkills = json['skills'];
    final skills = rawSkills is List ? rawSkills.map((s) => '$s').toList() : <String>[];

    final rawCerts = json['certifications'];
    final certs = rawCerts is List
        ? rawCerts.whereType<Map>().map((c) => Map<String, dynamic>.from(c)).toList()
        : <Map<String, dynamic>>[];

    return AuthUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      employeeCode: json['employee_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isAttendanceApplicable: json['is_attendance_applicable'] as bool? ?? true,
      salary: (json['salary'] is num)
          ? (json['salary'] as num).toDouble()
          : (json['salary'] is String ? double.tryParse(json['salary'] as String) : null),
      roleSlug: role['slug'] as String? ?? '',
      roleName: role['name'] as String? ?? '',
      roleLevel: (role['level'] as num?)?.toInt() ?? 0,
      companyName: nameOf(json['company']),
      departmentName: nameOf(json['department']),
      designationName: nameOf(json['designation']),
      reportsToName: nameOf(json['reports_to']),
      dob: json['dob'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      employmentType: json['employment_type'] as String?,
      probationEndDate: json['probation_end_date'] as String?,
      skills: skills,
      certifications: certs,
      permissions: permissions,
    );
  }
}
