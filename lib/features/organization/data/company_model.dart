class Company {
  const Company({
    required this.id,
    required this.name,
    required this.code,
    this.legalName,
    this.email,
    this.phone,
    this.address,
    this.logoPath,
    this.timezone = 'UTC',
    this.isActive = true,
    this.departmentsCount,
    this.employeesCount,
  });

  final int id;
  final String name;
  final String code;
  final String? legalName;
  final String? email;
  final String? phone;
  final String? address;
  final String? logoPath;
  final String timezone;
  final bool isActive;
  final int? departmentsCount;
  final int? employeesCount;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      legalName: json['legal_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      logoPath: json['logo_path'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      isActive: json['is_active'] as bool? ?? true,
      departmentsCount: (json['departments_count'] as num?)?.toInt(),
      employeesCount: (json['employees_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'legal_name': legalName,
      'email': email,
      'phone': phone,
      'address': address,
      'timezone': timezone,
    };
  }
}
