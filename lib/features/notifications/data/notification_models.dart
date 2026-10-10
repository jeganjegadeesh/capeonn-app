enum NotificationCategory {
  all,
  unread,
  tasks,
  projects,
  chat,
}

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

  NotificationCategory get category {
    if (type.startsWith('task_')) return NotificationCategory.tasks;
    if (type.startsWith('project_')) return NotificationCategory.projects;
    if (type.startsWith('chat_')) return NotificationCategory.chat;
    return NotificationCategory.all;
  }

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

class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.taskAlerts,
    required this.deadlineAlerts,
    required this.chatAlerts,
    required this.projectAlerts,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool taskAlerts;
  final bool deadlineAlerts;
  final bool chatAlerts;
  final bool projectAlerts;

  factory NotificationPreferencesModel.defaults() {
    return const NotificationPreferencesModel(
      pushEnabled: true,
      emailEnabled: true,
      taskAlerts: true,
      deadlineAlerts: true,
      chatAlerts: true,
      projectAlerts: true,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      taskAlerts: json['task_alerts'] as bool? ?? true,
      deadlineAlerts: json['deadline_alerts'] as bool? ?? true,
      chatAlerts: json['chat_alerts'] as bool? ?? true,
      projectAlerts: json['project_alerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'task_alerts': taskAlerts,
      'deadline_alerts': deadlineAlerts,
      'chat_alerts': chatAlerts,
      'project_alerts': projectAlerts,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? taskAlerts,
    bool? deadlineAlerts,
    bool? chatAlerts,
    bool? projectAlerts,
  }) {
    return NotificationPreferencesModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      taskAlerts: taskAlerts ?? this.taskAlerts,
      deadlineAlerts: deadlineAlerts ?? this.deadlineAlerts,
      chatAlerts: chatAlerts ?? this.chatAlerts,
      projectAlerts: projectAlerts ?? this.projectAlerts,
    );
  }
}
