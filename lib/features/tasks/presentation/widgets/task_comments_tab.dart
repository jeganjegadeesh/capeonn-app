import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/services/file_download_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../projects/application/projects_controller.dart';
import '../../application/tasks_providers.dart';
import '../../data/task_comment_models.dart';
import '../../data/task_repository.dart';

class _PendingAttachment {
  final String name;
  final int size;
  final List<int> bytes;
  int? uploadId;

  _PendingAttachment({
    required this.name,
    required this.size,
    required this.bytes,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class TaskCommentsTab extends ConsumerStatefulWidget {
  const TaskCommentsTab({
    super.key,
    required this.taskId,
    required this.projectId,
    required this.currentUser,
  });

  final int taskId;
  final int projectId;
  final dynamic currentUser;

  @override
  ConsumerState<TaskCommentsTab> createState() => _TaskCommentsTabState();
}

class _TaskCommentsTabState extends ConsumerState<TaskCommentsTab> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  TaskCommentModel? _replyingTo;
  final List<_PendingAttachment> _pendingAttachments = [];
  final Set<int> _pendingMentionIds = {};

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty) {
        final added = <_PendingAttachment>[];
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final size = file.lengthSync() ?? bytes.length;
          if (file.name.isNotEmpty) {
            added.add(_PendingAttachment(
              name: file.name,
              size: size,
              bytes: bytes,
            ));
          }
        }
        if (added.isNotEmpty) {
          setState(() {
            _pendingAttachments.addAll(added);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to pick file: $e');
      }
    }
  }

  Future<void> _showMentionPicker() async {
    try {
      final project = await ref.read(projectDetailProvider(widget.projectId).future);
      final members = project.members;
      if (!mounted) return;

      if (members.isEmpty) {
        AppToast.info(context, 'No project members available to mention.');
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Mention Project Member',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (_, index) {
                      final m = members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        title: Text(m.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        subtitle: Text(m.roleName ?? m.projectRole, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _insertMention(m.userId, m.name);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e);
      }
    }
  }

  void _insertMention(int userId, String name) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final mentionText = '@$name ';
    _pendingMentionIds.add(userId);

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, mentionText);
      _commentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + mentionText.length),
      );
    } else {
      _commentController.text = '$text$mentionText';
      _commentController.selection = TextSelection.collapsed(offset: _commentController.text.length);
    }
    _focusNode.requestFocus();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if ((text.isEmpty && _pendingAttachments.isEmpty) || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(taskRepositoryProvider);

      // 1. Upload pending attachments if any
      final uploadIds = <int>[];
      for (final att in _pendingAttachments) {
        if (att.uploadId != null) {
          uploadIds.add(att.uploadId!);
        } else {
          final res = await repo.uploadAttachment(
            bytes: att.bytes,
            fileName: att.name,
          );
          final id = (res['id'] as num?)?.toInt();
          if (id != null) {
            att.uploadId = id;
            uploadIds.add(id);
          }
        }
      }

      // 2. Post comment with mentions and attachments
      await repo.addComment(
        widget.taskId,
        comment: text.isEmpty ? 'Shared attachments' : text,
        parentId: _replyingTo?.id,
        mentions: _pendingMentionIds.isNotEmpty ? _pendingMentionIds.toList() : null,
        uploadIds: uploadIds.isNotEmpty ? uploadIds : null,
      );

      _commentController.clear();
      setState(() {
        _replyingTo = null;
        _pendingAttachments.clear();
        _pendingMentionIds.clear();
        _isSubmitting = false;
      });

      // Refresh comments and task details
      ref.invalidate(taskCommentsProvider(widget.taskId));
      ref.invalidate(taskDetailProvider(widget.taskId));
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        AppToast.error(context, e);
      }
    }
  }

  Future<void> _showEditHistory(TaskCommentModel comment) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final edits = await repo.getCommentHistory(widget.taskId, comment.id);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Comment Edit History',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (edits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No revision history recorded for this comment.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: edits.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (_, index) {
                        final edit = edits[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  edit.userName ?? 'User',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  edit.createdAt != null ? _formatTime(edit.createdAt!) : '',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Previous:',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.rose),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    edit.oldComment,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Updated to:',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    edit.newComment,
                                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e);
      }
    }
  }

  Future<void> _editComment(TaskCommentModel comment) async {
    final editController = TextEditingController(text: comment.comment);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Edit Comment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && editController.text.trim().isNotEmpty && editController.text.trim() != comment.comment) {
      try {
        final repo = ref.read(taskRepositoryProvider);
        await repo.updateComment(widget.taskId, comment.id, comment: editController.text.trim());
        ref.invalidate(taskCommentsProvider(widget.taskId));
      } catch (e) {
        if (mounted) {
          AppToast.error(context, e);
        }
      }
    }
  }

  Future<void> _deleteComment(TaskCommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Comment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(taskRepositoryProvider);
        await repo.deleteComment(widget.taskId, comment.id);
        ref.invalidate(taskCommentsProvider(widget.taskId));
        ref.invalidate(taskDetailProvider(widget.taskId));
      } catch (e) {
        if (mounted) {
          AppToast.error(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));

    return Column(
      children: [
        // Comments List
        Expanded(
          child: commentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 36, color: AppColors.rose),
                    const SizedBox(height: 8),
                    Text(
                      ApiException.cleanMessage(err),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(taskCommentsProvider(widget.taskId)),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (comments) {
              if (comments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chat_bubble_outline, size: 32, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ask a question, share progress updates, or discuss requirements with your team.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildCommentItem(comments[index]);
                },
              );
            },
          ),
        ),

        // Composer Divider
        Divider(height: 1, color: AppColors.border),

        // Replying Banner
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying to ${_replyingTo!.userName ?? "User"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _replyingTo = null),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

        // Pending Attachments Chips
        if (_pendingAttachments.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            color: AppColors.surface,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _pendingAttachments.map((att) {
                return Chip(
                  avatar: const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                  label: Text(
                    '${att.name} (${att.formattedSize})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() {
                      _pendingAttachments.remove(att);
                    });
                  },
                  backgroundColor: AppColors.surfaceHover,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),

        // In-line Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mention Button
              IconButton(
                onPressed: _showMentionPicker,
                icon: const Icon(Icons.alternate_email, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Mention Member',
                splashRadius: 20,
              ),

              // Attachment Button
              IconButton(
                onPressed: _pickAttachments,
                icon: const Icon(Icons.attach_file, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Attach Files',
                splashRadius: 20,
              ),

              const SizedBox(width: 4),

              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Write a reply...' : 'Write a comment or mention @team...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceHover,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _submitComment,
                      icon: Icon(Icons.send_rounded, color: AppColors.primary),
                      splashRadius: 20,
                      tooltip: 'Post Comment',
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(TaskCommentModel comment) {
    final authorName = comment.userName ?? 'Unknown';
    final roleName = comment.userRoleName ?? '';
    final initials = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Role, Timestamp, Menu
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (roleName.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          roleName,
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    if (comment.isEdited || comment.editsCount > 0) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showEditHistory(comment),
                        child: Text(
                          '(edited)',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (comment.createdAt != null)
                Text(
                  _formatTime(comment.createdAt!),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              if (comment.canEdit || comment.canDelete)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'edit') _editComment(comment);
                    if (val == 'delete') _deleteComment(comment);
                  },
                  itemBuilder: (_) => [
                    if (comment.canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (comment.canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Comment Text
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 36, bottom: 6),
            child: SelectableText(
              comment.comment,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
          ),

          // Attachments rendering
          if (comment.attachmentFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 8),
              child: _buildAttachmentsList(comment.attachmentFiles),
            ),

          // Action row (Reply trigger)
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: InkWell(
              onTap: () {
                setState(() => _replyingTo = comment);
                _focusNode.requestFocus();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          // Nested Replies
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                children: comment.replies.map((reply) => _buildReplyItem(reply, parentComment: comment)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(TaskCommentModel reply, {required TaskCommentModel parentComment}) {
    final authorName = reply.userName ?? 'Unknown';
    final initials = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (reply.isEdited || reply.editsCount > 0) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showEditHistory(reply),
                        child: Text(
                          '(edited)',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (reply.createdAt != null)
                Text(
                  _formatTime(reply.createdAt!),
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              if (reply.canEdit || reply.canDelete)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 14, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'edit') _editComment(reply);
                    if (val == 'delete') _deleteComment(reply);
                  },
                  itemBuilder: (_) => [
                    if (reply.canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    if (reply.canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 30),
            child: SelectableText(
              reply.comment,
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
            ),
          ),
          if (reply.attachmentFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4, bottom: 4),
              child: _buildAttachmentsList(reply.attachmentFiles),
            ),
          // Reply trigger targets parent comment to enforce max depth 1
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4),
            child: InkWell(
              onTap: () {
                setState(() => _replyingTo = parentComment);
                _focusNode.requestFocus();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(List<TaskCommentAttachmentModel> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: attachments.map((att) {
        final icon = att.isImage
            ? Icons.image_outlined
            : att.isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined;

        return InkWell(
          onTap: () {
            final downloadUrl = att.downloadUrl ?? att.url;
            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              FileDownloadService.downloadFile(
                context: context,
                rawUrl: downloadUrl,
                fileName: att.fileName,
                mimeType: att.mimeType,
                autoOpen: true,
              );
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    att.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${att.formattedSize})',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(width: 4),
                Icon(Icons.download, size: 12, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
