class RoleItem {
  const RoleItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.level,
    this.description,
    this.isSystem = true,
  });

  final int id;
  final String name;
  final String slug;
  final int level;
  final String? description;
  final bool isSystem;

  factory RoleItem.fromJson(Map<String, dynamic> json) {
    return RoleItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      isSystem: json['is_system'] as bool? ?? true,
    );
  }
}
