import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/application/auth_controller.dart';
import '../application/chat_controller.dart';
import '../data/chat_models.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  List<Map<String, dynamic>> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      ref.read(chatRoomProvider(widget.conversationId).notifier).loadOlderMessages();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    setState(() => _isSending = true);
    final atts = List<Map<String, dynamic>>.from(_pendingAttachments);

    _messageController.clear();
    setState(() => _pendingAttachments = []);

    try {
      await ref.read(chatRoomProvider(widget.conversationId).notifier).sendMessage(
        message: text.isNotEmpty ? text : null,
        attachments: atts.isNotEmpty ? atts : null,
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to send message: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showAttachmentDialog() {
    final nameController = TextEditingController(text: 'project_document.pdf');
    String type = 'pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.attach_file, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Attach File or Image'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select attachment type:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF Document (.pdf)')),
                  DropdownMenuItem(value: 'image', child: Text('Image (.png, .jpg)')),
                  DropdownMenuItem(value: 'doc', child: Text('Office Document (.docx)')),
                  DropdownMenuItem(value: 'zip', child: Text('Archive (.zip)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      type = val;
                      nameController.text = val == 'image'
                          ? 'screenshot.png'
                          : val == 'doc'
                              ? 'specification.docx'
                              : val == 'zip'
                                  ? 'archive.zip'
                                  : 'document.pdf';
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final fname = nameController.text.trim();
                if (fname.isEmpty) return;
                Navigator.pop(ctx);

                final mime = type == 'image'
                    ? 'image/png'
                    : type == 'pdf'
                        ? 'application/pdf'
                        : type == 'zip'
                            ? 'application/zip'
                            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

                setState(() {
                  _pendingAttachments.add({
                    'file_path': 'uploads/$fname',
                    'file_name': fname,
                    'file_size': 1024 * 250, // 250 KB
                    'mime_type': mime,
                  });
                });
              },
              child: const Text('Add Attachment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatStateAsync = ref.watch(chatRoomProvider(widget.conversationId));
    final currentUser = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: chatStateAsync.when(
          data: (state) {
            final conv = state.conversation;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: conv.isDirect
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : conv.isGroup
                          ? AppColors.emerald.withValues(alpha: 0.15)
                          : AppColors.amber.withValues(alpha: 0.15),
                  child: Icon(
                    conv.isDirect
                        ? Icons.person
                        : conv.isGroup
                            ? Icons.group
                            : Icons.folder_special,
                    color: conv.isDirect
                        ? AppColors.primary
                        : conv.isGroup
                            ? AppColors.emerald
                            : AppColors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        conv.isDirect
                            ? 'Direct Chat'
                            : conv.isGroup
                                ? '${conv.participants.length} members'
                                : 'Project Discussion',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Text('Loading chat...'),
          error: (_, _) => const Text('Chat Room'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(chatRoomProvider(widget.conversationId)),
          ),
        ],
      ),
      body: chatStateAsync.when(
        data: (state) => Column(
          children: [
            // Messages View
            Expanded(
              child: state.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 54, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No messages yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Send a greeting to start the conversation!',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: state.messages.length + (state.isLoadingOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        final msg = state.messages[index];
                        final isSelf = msg.userId == currentUser?.id;

                        return _MessageBubble(
                          message: msg,
                          isSelf: isSelf,
                          onReply: () => ref
                              .read(chatRoomProvider(widget.conversationId).notifier)
                              .setReplyingTo(msg),
                          onDelete: () => ref
                              .read(chatRoomProvider(widget.conversationId).notifier)
                              .deleteMessage(msg.id),
                        );
                      },
                    ),
            ),

            // Pending Attachments Bar
            if (_pendingAttachments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attached: ${_pendingAttachments.map((a) => a['file_name']).join(', ')}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _pendingAttachments = []),
                    ),
                  ],
                ),
              ),

            // Replying To Banner
            if (state.replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${state.replyingTo!.userName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            state.replyingTo!.message ?? 'Attachment',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref
                          .read(chatRoomProvider(widget.conversationId).notifier)
                          .setReplyingTo(null),
                    ),
                  ],
                ),
              ),

            // Input Row
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                      tooltip: 'Attach file',
                      onPressed: _showAttachmentDialog,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: AppColors.background,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isSending ? null : _sendMessage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load chat: $err', style: TextStyle(color: AppColors.rose)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(chatRoomProvider(widget.conversationId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isSelf,
    required this.onReply,
    required this.onDelete,
  });

  final ChatMessageModel message;
  final bool isSelf;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                onReply();
              },
            ),
            if (message.message != null && message.message!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Text'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.message!));
                  Navigator.pop(ctx);
                  AppToast.success(context, 'Copied to clipboard');
                },
              ),
            if (isSelf)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.rose),
                title: const Text('Delete Message', style: TextStyle(color: AppColors.rose)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSelf) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                message.userName.isNotEmpty ? message.userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showContextMenu(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelf ? AppColors.primary : theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSelf ? 16 : 4),
                    bottomRight: Radius.circular(isSelf ? 4 : 16),
                  ),
                  border: isSelf ? null : Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender Name (for incoming messages in group chats)
                    if (!isSelf)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.userName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (message.userRole != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(${message.userRole})',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Quoted Reply Preview
                    if (message.replyToUserName != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isSelf ? Colors.black : Colors.white).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(
                              color: isSelf ? Colors.white70 : AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyToUserName!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelf ? Colors.white : AppColors.primary,
                              ),
                            ),
                            Text(
                              message.replyToMessage ?? 'Attachment',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelf ? Colors.white70 : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                    // Linked Task Badge
                    if (message.hasTaskLink)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isSelf ? Colors.white : AppColors.primary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: isSelf ? Colors.white : AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Task: ${message.taskTitle ?? "Task #${message.taskId}"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelf ? Colors.white : AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Attachments Cards
                    if (message.hasAttachments)
                      ...message.attachments.map((att) => _buildAttachmentCard(att, isSelf)),

                    // Text Content
                    if (message.message != null && message.message!.isNotEmpty)
                      Text(
                        message.message!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelf ? Colors.white : AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Timestamp & Status ticks
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelf ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(ChatAttachmentModel att, bool isSelf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isSelf ? Colors.black : Colors.white).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            att.isImage
                ? Icons.image
                : att.isPdf
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
            size: 24,
            color: isSelf ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelf ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  att.formattedSize,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelf ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
