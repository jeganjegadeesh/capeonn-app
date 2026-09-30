class Designation {
  const Designation({
    required this.id,
    required this.name,
    this.isActive = true,
    this.employeesCount,
  });

  final int id;
  final String name;
  final bool isActive;
  final int? employeesCount;

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      employeesCount: (json['employees_count'] as num?)?.toInt(),
    );
  }
}
