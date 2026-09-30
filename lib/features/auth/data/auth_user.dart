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
    this.companyName,
    this.departmentName,
    this.designationName,
    this.reportsToName,
    this.permissions = const {},
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? employeeCode;
  final bool isActive;

  final String roleSlug; // admin | manager | team_lead | employee
  final String roleName;
  final int roleLevel;

  final String? companyName;
  final String? departmentName;
  final String? designationName;
  final String? reportsToName;

  /// permission slug -> scope (all | department | team | assigned | self)
  final Map<String, String> permissions;

  bool get isAdmin => roleSlug == 'admin';

  /// Use this to show/hide screens and buttons. The server enforces the same rules anyway.
  bool can(String permission) => permissions.containsKey(permission);

  String? scopeOf(String permission) => permissions[permission];

  bool get canViewOrganization => can('organization.view');
  bool get canManageOrganization => can('organization.manage');
  bool get canViewEmployees => can('employees.view');
  bool get canManageEmployees => can('employees.manage');
  bool get canViewHierarchy => can('employees.view');

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    String? nameOf(dynamic value) => value is Map ? value['name'] as String? : null;

    final role = json['role'] is Map ? json['role'] as Map : const {};
    final permissions = <String, String>{};
    final rawPermissions = json['permissions'];
    if (rawPermissions is Map) {
      rawPermissions.forEach((key, value) => permissions['$key'] = '$value');
    }

    return AuthUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      employeeCode: json['employee_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      roleSlug: role['slug'] as String? ?? '',
      roleName: role['name'] as String? ?? '',
      roleLevel: (role['level'] as num?)?.toInt() ?? 0,
      companyName: nameOf(json['company']),
      departmentName: nameOf(json['department']),
      designationName: nameOf(json['designation']),
      reportsToName: nameOf(json['reports_to']),
      permissions: permissions,
    );
  }
}
