import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/tasks_providers.dart';
import '../../data/task_comment_models.dart';
import '../../data/task_repository.dart';

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

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.addComment(
        widget.taskId,
        comment: text,
        parentId: _replyingTo?.id,
      );

      _commentController.clear();
      setState(() {
        _replyingTo = null;
        _isSubmitting = false;
      });

      // Refresh comments and task details
      ref.invalidate(taskCommentsProvider(widget.taskId));
      ref.invalidate(taskDetailProvider(widget.taskId));
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiException.cleanMessage(e)),
            backgroundColor: AppColors.rose,
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.cleanMessage(e)), backgroundColor: AppColors.rose),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.cleanMessage(e)), backgroundColor: AppColors.rose),
          );
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

        // In-line Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Write a reply...' : 'Write a comment on this task...',
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
                    if (comment.isEdited) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(edited)',
                        style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textMuted),
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
                children: comment.replies.map((reply) => _buildReplyItem(reply)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(TaskCommentModel reply) {
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
                child: Text(
                  authorName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
        ],
      ),
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
