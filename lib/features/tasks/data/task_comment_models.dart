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

class TaskCommentModel {
  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    this.parentId,
    required this.comment,
    this.attachments = const [],
    this.isEdited = false,
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
  final bool isEdited;
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

    return TaskCommentModel(
      id: (json['id'] as num).toInt(),
      taskId: (json['task_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      parentId: (json['parent_id'] as num?)?.toInt(),
      comment: json['comment'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?) ?? const [],
      isEdited: json['is_edited'] as bool? ?? false,
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
    String? editedAt,
    List<TaskCommentModel>? replies,
  }) {
    return TaskCommentModel(
      id: id,
      taskId: taskId,
      userId: userId,
      parentId: parentId,
      comment: comment ?? this.comment,
      attachments: attachments,
      isEdited: isEdited ?? this.isEdited,
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
