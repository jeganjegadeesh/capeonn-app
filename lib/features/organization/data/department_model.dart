class DepartmentHead {
  const DepartmentHead({required this.id, required this.name});

  final int id;
  final String name;

  factory DepartmentHead.fromJson(Map<String, dynamic> json) {
    return DepartmentHead(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

class Department {
  const Department({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.head,
    this.employeesCount,
  });

  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final DepartmentHead? head;
  final int? employeesCount;

  factory Department.fromJson(Map<String, dynamic> json) {
    DepartmentHead? headObj;
    if (json['head'] is Map) {
      headObj = DepartmentHead.fromJson(Map<String, dynamic>.from(json['head'] as Map));
    }

    return Department(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      head: headObj,
      employeesCount: (json['employees_count'] as num?)?.toInt(),
    );
  }
}
