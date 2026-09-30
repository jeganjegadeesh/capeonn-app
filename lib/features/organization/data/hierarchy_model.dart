class HierarchyNode {
  const HierarchyNode({
    required this.id,
    required this.name,
    this.employeeCode,
    this.isActive = true,
    this.role,
    this.designation,
    this.reports = const [],
  });

  final int id;
  final String name;
  final String? employeeCode;
  final bool isActive;
  final String? role;
  final String? designation;
  final List<HierarchyNode> reports;

  factory HierarchyNode.fromJson(Map<String, dynamic> json) {
    final rawReports = json['reports'];
    final reportsList = <HierarchyNode>[];
    if (rawReports is List) {
      for (final r in rawReports) {
        if (r is Map) {
          reportsList.add(HierarchyNode.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }

    return HierarchyNode(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      employeeCode: json['employee_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String?,
      designation: json['designation'] as String?,
      reports: reportsList,
    );
  }

  /// Total count of direct and indirect reports
  int get totalReportsCount {
    int count = reports.length;
    for (final child in reports) {
      count += child.totalReportsCount;
    }
    return count;
  }
}
