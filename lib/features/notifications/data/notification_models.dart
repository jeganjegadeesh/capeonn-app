class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  int? get conversationId {
    final conv = data['conversation_id'];
    if (conv is num) return conv.toInt();
    if (conv is String) return int.tryParse(conv);
    return null;
  }

  int? get taskId {
    final t = data['task_id'];
    if (t is num) return t.toInt();
    if (t is String) return int.tryParse(t);
    return null;
  }

  int? get projectId {
    final p = data['project_id'];
    if (p is num) return p.toInt();
    if (p is String) return int.tryParse(p);
    return null;
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: (json['body'] as String?) ?? (json['message'] as String?) ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class PaginatedNotifications {
  const PaginatedNotifications({
    required this.items,
    required this.unreadCount,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  final List<AppNotificationItem> items;
  final int unreadCount;
  final int total;
  final int currentPage;
  final int lastPage;

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'] as List? ?? [];
    final meta = json['meta'] as Map? ?? {};
    return PaginatedNotifications(
      items: rawItems
          .whereType<Map>()
          .map((m) => AppNotificationItem.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}
