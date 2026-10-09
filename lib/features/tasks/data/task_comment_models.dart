class TaskCommentMentionModel {
  const TaskCommentMentionModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory TaskCommentMentionModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentMentionModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TaskCommentAttachmentModel {
  const TaskCommentAttachmentModel({
    required this.id,
    required this.fileName,
    this.fileSize = 0,
    this.mimeType = '',
    this.url,
    this.downloadUrl,
    this.isImage = false,
    this.isPdf = false,
  });

  final int id;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? url;
  final String? downloadUrl;
  final bool isImage;
  final bool isPdf;

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory TaskCommentAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentAttachmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: json['file_name'] as String? ?? 'attachment',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? '',
      url: json['url'] as String?,
      downloadUrl: json['download_url'] as String?,
      isImage: json['is_image'] as bool? ?? false,
      isPdf: json['is_pdf'] as bool? ?? false,
    );
  }
}

class TaskCommentEditModel {
  const TaskCommentEditModel({
    required this.id,
    required this.oldComment,
    required this.newComment,
    this.createdAt,
    this.userId,
    this.userName,
    this.userAvatarUrl,
  });

  final int id;
  final String oldComment;
  final String newComment;
  final String? createdAt;
  final int? userId;
  final String? userName;
  final String? userAvatarUrl;

  factory TaskCommentEditModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return TaskCommentEditModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      oldComment: json['old_comment'] as String? ?? '',
      newComment: json['new_comment'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      userId: (user?['id'] as num?)?.toInt(),
      userName: user?['name'] as String?,
      userAvatarUrl: user?['avatar_url'] as String?,
    );
  }
}

class TaskCommentModel {
  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    this.parentId,
    required this.comment,
    this.attachments = const [],
    this.attachmentFiles = const [],
    this.isEdited = false,
    this.editsCount = 0,
    this.editedAt,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.userRoleName,
    this.userRoleSlug,
    this.canEdit = false,
    this.canDelete = false,
    this.mentions = const [],
    this.replies = const [],
  });

  final int id;
  final int taskId;
  final int userId;
  final int? parentId;
  final String comment;
  final List<dynamic> attachments;
  final List<TaskCommentAttachmentModel> attachmentFiles;
  final bool isEdited;
  final int editsCount;
  final String? editedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final String? userRoleName;
  final String? userRoleSlug;
  final bool canEdit;
  final bool canDelete;
  final List<TaskCommentMentionModel> mentions;
  final List<TaskCommentModel> replies;

  bool get isReply => parentId != null;

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final roleMap = userMap?['role'] as Map<String, dynamic>?;

    final rawMentions = json['mentions'] as List<dynamic>? ?? [];
    final mentions = rawMentions
        .whereType<Map<String, dynamic>>()
        .map((m) => TaskCommentMentionModel.fromJson(m))
        .toList();

    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    final replies = rawReplies
        .whereType<Map<String, dynamic>>()
        .map((r) => TaskCommentModel.fromJson(r))
        .toList();

    final rawAttachments = (json['attachments'] as List<dynamic>?) ?? const [];
    final attachmentFiles = rawAttachments
        .whereType<Map<String, dynamic>>()
        .map((a) => TaskCommentAttachmentModel.fromJson(a))
        .toList();

    final isEdited = json['is_edited'] as bool? ?? false;
    final editsCount = (json['edits_count'] as num?)?.toInt() ?? (isEdited ? 1 : 0);

    return TaskCommentModel(
      id: (json['id'] as num).toInt(),
      taskId: (json['task_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      parentId: (json['parent_id'] as num?)?.toInt(),
      comment: json['comment'] as String? ?? '',
      attachments: rawAttachments,
      attachmentFiles: attachmentFiles,
      isEdited: isEdited,
      editsCount: editsCount,
      editedAt: json['edited_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      userName: userMap?['name'] as String?,
      userEmail: userMap?['email'] as String?,
      userAvatarUrl: userMap?['avatar_url'] as String?,
      userRoleName: roleMap?['name'] as String?,
      userRoleSlug: roleMap?['slug'] as String?,
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
      mentions: mentions,
      replies: replies,
    );
  }

  TaskCommentModel copyWith({
    String? comment,
    bool? isEdited,
    int? editsCount,
    String? editedAt,
    List<TaskCommentModel>? replies,
    List<TaskCommentAttachmentModel>? attachmentFiles,
  }) {
    return TaskCommentModel(
      id: id,
      taskId: taskId,
      userId: userId,
      parentId: parentId,
      comment: comment ?? this.comment,
      attachments: attachments,
      attachmentFiles: attachmentFiles ?? this.attachmentFiles,
      isEdited: isEdited ?? this.isEdited,
      editsCount: editsCount ?? this.editsCount,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userName: userName,
      userEmail: userEmail,
      userAvatarUrl: userAvatarUrl,
      userRoleName: userRoleName,
      userRoleSlug: userRoleSlug,
      canEdit: canEdit,
      canDelete: canDelete,
      mentions: mentions,
      replies: replies ?? this.replies,
    );
  }
}
