import 'role_model.dart';

class DepartmentRef {
  const DepartmentRef({required this.id, required this.name});
  final int id;
  final String name;

  factory DepartmentRef.fromJson(Map<String, dynamic> json) {
    return DepartmentRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

class DesignationRef {
  const DesignationRef({required this.id, required this.name});
  final int id;
  final String name;

  factory DesignationRef.fromJson(Map<String, dynamic> json) {
    return DesignationRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

class SupervisorRef {
  const SupervisorRef({required this.id, required this.name});
  final int id;
  final String name;

  factory SupervisorRef.fromJson(Map<String, dynamic> json) {
    return SupervisorRef(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.employeeCode,
    this.isActive = true,
    this.joinedOn,
    this.lastLoginAt,
    this.department,
    this.designation,
    this.role,
    this.reportsTo,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? employeeCode;
  final bool isActive;
  final String? joinedOn;
  final String? lastLoginAt;
  final DepartmentRef? department;
  final DesignationRef? designation;
  final RoleItem? role;
  final SupervisorRef? reportsTo;

  int? get departmentId => department?.id;
  int? get designationId => designation?.id;
  int? get roleId => role?.id;
  int? get reportsToId => reportsTo?.id;

  String get departmentName => department?.name ?? '—';
  String get designationName => designation?.name ?? '—';
  String get roleName => role?.name ?? '—';
  String get roleSlug => role?.slug ?? '';
  String get reportsToName => reportsTo?.name ?? '—';

  factory Employee.fromJson(Map<String, dynamic> json) {
    DepartmentRef? dept;
    if (json['department'] is Map) {
      dept = DepartmentRef.fromJson(Map<String, dynamic>.from(json['department'] as Map));
    }

    DesignationRef? desig;
    if (json['designation'] is Map) {
      desig = DesignationRef.fromJson(Map<String, dynamic>.from(json['designation'] as Map));
    }

    RoleItem? roleItem;
    if (json['role'] is Map) {
      final r = Map<String, dynamic>.from(json['role'] as Map);
      roleItem = RoleItem(
        id: (r['id'] as num?)?.toInt() ?? 0,
        name: r['name'] as String? ?? '',
        slug: r['slug'] as String? ?? '',
        level: (r['level'] as num?)?.toInt() ?? 0,
      );
    }

    SupervisorRef? supervisor;
    if (json['reports_to'] is Map) {
      supervisor = SupervisorRef.fromJson(Map<String, dynamic>.from(json['reports_to'] as Map));
    }

    return Employee(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      employeeCode: json['employee_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      joinedOn: json['joined_on'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
      department: dept,
      designation: desig,
      role: roleItem,
      reportsTo: supervisor,
    );
  }
}

class PaginatedEmployees {
  const PaginatedEmployees({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<Employee> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPrevPage => currentPage > 1;

  factory PaginatedEmployees.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final itemsList = <Employee>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          itemsList.add(Employee.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final meta = json['meta'] is Map ? json['meta'] as Map : const {};

    return PaginatedEmployees(
      items: itemsList,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? 15,
      total: (meta['total'] as num?)?.toInt() ?? itemsList.length,
    );
  }
}
