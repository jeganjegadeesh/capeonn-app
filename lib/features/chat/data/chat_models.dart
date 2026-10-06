class ChatAttachmentModel {
  const ChatAttachmentModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.url,
    this.createdAt,
  });

  final int id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String url;
  final DateTime? createdAt;

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.webp') ||
      fileName.toLowerCase().endsWith('.gif');

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  String get formattedSize {
    if (fileSize >= 1048576) {
      return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
    }
    if (fileSize >= 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSize B';
  }

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: json['file_name'] as String? ?? 'Attachment',
      filePath: json['file_path'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      url: json['url'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    'file_path': filePath,
    'file_size': fileSize,
    'mime_type': mimeType,
    'url': url,
    'created_at': createdAt?.toIso8601String(),
  };
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userRole,
    this.userRoleSlug,
    this.message,
    required this.type,
    this.replyToId,
    this.replyToMessage,
    this.replyToUserName,
    this.taskId,
    this.taskTitle,
    this.taskStatus,
    this.taskPriority,
    this.attachments = const [],
    this.isEdited = false,
    this.editedAt,
    this.createdAt,
  });

  final int id;
  final int conversationId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String? userRole;
  final String? userRoleSlug;
  final String? message;
  final String type; // text, file, system
  final int? replyToId;
  final String? replyToMessage;
  final String? replyToUserName;
  final int? taskId;
  final String? taskTitle;
  final String? taskStatus;
  final String? taskPriority;
  final List<ChatAttachmentModel> attachments;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime? createdAt;

  bool get isSystem => type == 'system';
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasTaskLink => taskId != null && taskId! > 0;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map : const {};
    final replyTo = json['reply_to'] is Map ? json['reply_to'] as Map : null;
    final replyToUser = replyTo != null && replyTo['user'] is Map ? replyTo['user'] as Map : null;
    final task = json['task'] is Map ? json['task'] as Map : null;

    final rawAtts = json['attachments'];
    final attsList = rawAtts is List
        ? rawAtts.whereType<Map>().map((a) => ChatAttachmentModel.fromJson(Map<String, dynamic>.from(a))).toList()
        : <ChatAttachmentModel>[];

    return ChatMessageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      userId: (user['id'] as num?)?.toInt() ?? 0,
      userName: user['name'] as String? ?? 'User',
      userAvatar: user['avatar_url'] as String?,
      userRole: user['role'] is Map ? (user['role'] as Map)['name'] as String? : user['role'] as String?,
      userRoleSlug: user['role'] is Map ? (user['role'] as Map)['slug'] as String? : user['role_slug'] as String?,
      message: json['message'] as String?,
      type: json['type'] as String? ?? 'text',
      replyToId: (json['reply_to_id'] as num?)?.toInt() ?? (replyTo != null ? (replyTo['id'] as num?)?.toInt() : null),
      replyToMessage: replyTo != null ? replyTo['message'] as String? : null,
      replyToUserName: replyToUser != null
          ? replyToUser['name'] as String?
          : (replyTo != null ? replyTo['user_name'] as String? : null),
      taskId: (json['task_id'] as num?)?.toInt() ?? (task != null ? (task['id'] as num?)?.toInt() : null),
      taskTitle: task != null ? task['title'] as String? : null,
      taskStatus: task != null ? task['status'] as String? : null,
      taskPriority: task != null ? task['priority'] as String? : null,
      attachments: attsList,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null ? DateTime.tryParse(json['edited_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class ConversationParticipantModel {
  const ConversationParticipantModel({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.roleSlug,
    this.isOnline = false,
    this.lastSeenAt,
    this.lastReadAt,
    this.isMuted = false,
  });

  final int userId;
  final String name;
  final String? avatarUrl;
  final String role;
  final String? roleSlug;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? lastReadAt;
  final bool isMuted;

  bool get isAdmin => role == 'admin';

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) {
    final u = json['user'] is Map ? json['user'] as Map : null;
    final name = json['name'] as String? ?? u?['name'] as String? ?? 'Participant';
    final roleMap = u?['role'] is Map ? u!['role'] as Map : null;

    return ConversationParticipantModel(
      userId: (json['user_id'] as num?)?.toInt() ?? (u?['id'] as num?)?.toInt() ?? 0,
      name: name,
      avatarUrl: json['avatar_url'] as String? ?? u?['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      roleSlug: json['role_slug'] as String? ?? roleMap?['slug'] as String?,
      isOnline: json['is_online'] as bool? ?? (u?['is_online'] as bool? ?? false),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : (u?['last_seen_at'] != null ? DateTime.tryParse(u!['last_seen_at'].toString()) : null),
      lastReadAt: json['last_read_at'] != null ? DateTime.tryParse(json['last_read_at'].toString()) : null,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }
}

class UserPresenceModel {
  const UserPresenceModel({
    required this.userId,
    required this.userName,
    required this.isOnline,
    this.lastSeenAt,
  });

  final int userId;
  final String userName;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory UserPresenceModel.fromJson(Map<String, dynamic> json) {
    return UserPresenceModel(
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String? ?? json['name'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name': userName,
    'is_online': isOnline,
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.type,
    this.title,
    required this.displayName,
    this.projectId,
    this.projectName,
    this.projectCode,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.partnerIsOnline,
    this.partnerLastSeenAt,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.createdAt,
    this.latestMessage,
    this.participants = const [],
    this.canPost = true,
    this.canManage = false,
  });

  final int id;
  final String type; // direct, group, project
  final String? title;
  final String displayName;
  final int? projectId;
  final String? projectName;
  final String? projectCode;
  final int? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final bool? partnerIsOnline;
  final DateTime? partnerLastSeenAt;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final ChatMessageModel? latestMessage;
  final List<ConversationParticipantModel> participants;
  final bool canPost;
  final bool canManage;

  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';
  bool get isProject => type == 'project';

  String displayTitle([int? currentUserId]) {
    if (isDirect && currentUserId != null && participants.isNotEmpty) {
      final other = participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => participants.first,
      );
      if (other.name.isNotEmpty && other.name != 'Participant') {
        return other.name;
      }
    }
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (projectName != null && projectName!.trim().isNotEmpty) return projectName!.trim();
    return displayName.isNotEmpty ? displayName : 'Chat';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final proj = json['project'] is Map ? json['project'] as Map : null;
    final partner = json['partner'] is Map ? json['partner'] as Map : null;
    final latest = json['latest_message'] is Map ? json['latest_message'] as Map : null;

    final rawParticipants = json['participants'];
    final participantsList = rawParticipants is List
        ? rawParticipants.whereType<Map>().map((p) => ConversationParticipantModel.fromJson(Map<String, dynamic>.from(p))).toList()
        : <ConversationParticipantModel>[];

    final title = json['title'] as String?;
    final projName = proj != null ? proj['name'] as String? : null;

    return ConversationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'direct',
      title: title,
      displayName: json['display_name'] as String? ?? title ?? projName ?? 'Chat',
      projectId: (json['project_id'] as num?)?.toInt(),
      projectName: proj != null ? proj['name'] as String? : null,
      projectCode: proj != null ? proj['code'] as String? : null,
      partnerId: (partner?['id'] as num?)?.toInt(),
      partnerName: partner?['name'] as String?,
      partnerAvatarUrl: partner?['avatar_url'] as String?,
      partnerIsOnline: partner?['is_online'] as bool?,
      partnerLastSeenAt: partner?['last_seen_at'] != null ? DateTime.tryParse(partner!['last_seen_at'].toString()) : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      latestMessage: latest != null ? ChatMessageModel.fromJson(Map<String, dynamic>.from(latest)) : null,
      participants: participantsList,
      canPost: json['can_post'] as bool? ?? true,
      canManage: json['can_manage'] as bool? ?? false,
    );
  }
}

class ProjectFileModel {
  const ProjectFileModel({
    required this.id,
    required this.projectId,
    this.taskId,
    this.taskTitle,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.formattedSize,
    required this.mimeType,
    required this.category,
    this.description,
    required this.url,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderRole,
    this.uploaderRoleSlug,
    this.createdAt,
  });

  final int id;
  final int projectId;
  final int? taskId;
  final String? taskTitle;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String formattedSize;
  final String mimeType;
  final String category; // specification, design, document, report, archive, general
  final String? description;
  final String url;
  final int uploaderId;
  final String uploaderName;
  final String? uploaderRole;
  final String? uploaderRoleSlug;
  final DateTime? createdAt;

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.webp');

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  bool get isDoc =>
      fileName.toLowerCase().endsWith('.doc') ||
      fileName.toLowerCase().endsWith('.docx') ||
      fileName.toLowerCase().endsWith('.txt') ||
      fileName.toLowerCase().endsWith('.rtf');

  bool get hasTaskLink => taskId != null && taskId! > 0;

  String get categoryDisplayName {
    if (category.isEmpty) return 'General';
    return category[0].toUpperCase() + category.substring(1);
  }

  factory ProjectFileModel.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploader'] is Map ? json['uploader'] as Map : const {};
    final size = (json['file_size'] as num?)?.toInt() ?? 0;
    String formatted = json['formatted_size'] as String? ?? '';
    if (formatted.isEmpty) {
      if (size >= 1048576) {
        formatted = '${(size / 1048576).toStringAsFixed(1)} MB';
      } else if (size >= 1024) {
        formatted = '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        formatted = '$size B';
      }
    }

    return ProjectFileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      taskId: (json['task_id'] as num?)?.toInt(),
      taskTitle: json['task_title'] as String?,
      fileName: json['file_name'] as String? ?? 'File',
      filePath: json['file_path'] as String? ?? '',
      fileSize: size,
      formattedSize: formatted,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      category: json['category'] as String? ?? 'general',
      description: json['description'] as String?,
      url: json['url'] as String? ?? '',
      uploaderId: (uploader['id'] as num?)?.toInt() ?? 0,
      uploaderName: uploader['name'] as String? ?? 'Uploader',
      uploaderRole: uploader['role'] as String?,
      uploaderRoleSlug: uploader['role_slug'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
