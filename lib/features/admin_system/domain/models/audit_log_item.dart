class AuditLogItem {
  const AuditLogItem({
    required this.id,
    required this.event,
    required this.description,
    required this.severity,
    this.userName,
    this.userEmail,
    this.ipAddress,
    required this.createdAt,
    this.metadata,
  });

  final int id;
  final String event;
  final String description;
  final String severity;
  final String? userName;
  final String? userEmail;
  final String? ipAddress;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;

    return AuditLogItem(
      id: json['id'] as int? ?? 0,
      event: json['event'] as String? ?? 'system.event',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      userName: user != null ? user['name'] as String? : null,
      userEmail: user != null ? user['email'] as String? : null,
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }
}
