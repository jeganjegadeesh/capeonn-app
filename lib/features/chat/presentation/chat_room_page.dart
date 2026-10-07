import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/services/app_permission_service.dart';
import '../../../core/services/file_download_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../employees/data/employee_repository.dart';
import '../../tasks/data/task_models.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/presentation/widgets/task_detail_dialog.dart';
import '../application/chat_controller.dart';
import '../application/presence_controller.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';

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
  TaskItem? _selectedTask;
  Timer? _typingDebounce;
  bool _isCurrentlyTyping = false;
  List<ConversationParticipantModel> _mentionSuggestions = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    if (_isCurrentlyTyping) {
      ref.read(chatRepositoryProvider).sendTyping(widget.conversationId, false);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      ref.read(chatRoomProvider(widget.conversationId).notifier).loadOlderMessages();
    }
  }

  void _onTextChanged(String text, ConversationModel conv) {
    if (text.trim().isNotEmpty && !_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      ref.read(chatRepositoryProvider).sendTyping(widget.conversationId, true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        ref.read(chatRepositoryProvider).sendTyping(widget.conversationId, false);
      }
    });

    _checkForMentions(text, conv);
  }

  void _checkForMentions(String text, ConversationModel conv) {
    final selection = _messageController.selection;
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) {
      if (_mentionSuggestions.isNotEmpty) setState(() => _mentionSuggestions = []);
      return;
    }

    final beforeCursor = text.substring(0, cursor);
    final lastAt = beforeCursor.lastIndexOf('@');
    if (lastAt >= 0) {
      final afterAt = beforeCursor.substring(lastAt + 1);
      if (lastAt == 0 || beforeCursor[lastAt - 1] == ' ' || beforeCursor[lastAt - 1] == '\n') {
        if (!afterAt.contains(' ') && !afterAt.contains('\n')) {
          final query = afterAt.toLowerCase();
          final matches = conv.participants
              .where((p) => p.name.toLowerCase().contains(query))
              .toList();
          setState(() {
            _mentionSuggestions = matches;
          });
          return;
        }
      }
    }

    if (_mentionSuggestions.isNotEmpty) {
      setState(() => _mentionSuggestions = []);
    }
  }

  void _insertMention(ConversationParticipantModel p) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    final beforeCursor = text.substring(0, cursor);
    final lastAt = beforeCursor.lastIndexOf('@');
    if (lastAt >= 0) {
      final prefix = text.substring(0, lastAt);
      final suffix = text.substring(cursor);
      final mentionText = '@${p.name} ';
      final newText = '$prefix$mentionText$suffix';
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: prefix.length + mentionText.length),
      );
    }
    setState(() => _mentionSuggestions = []);
  }

  Future<void> _pickDeviceFiles() async {
    final hasPermission = await AppPermissionService.requestFileAccessPermission();
    if (!hasPermission && mounted) {
      AppToast.warning(context, 'Permission required to select files from device.');
      return;
    }

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty && mounted) {
        AppToast.info(context, 'Uploading attachment...');
        for (final f in files) {
          final ext = f.extension?.toLowerCase() ?? '';
          final mime = ext == 'png'
              ? 'image/png'
              : (ext == 'jpg' || ext == 'jpeg')
                  ? 'image/jpeg'
                  : ext == 'pdf'
                      ? 'application/pdf'
                      : ext == 'zip'
                          ? 'application/zip'
                          : (ext == 'doc' || ext == 'docx')
                              ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                              : 'application/octet-stream';

          final bytes = await f.readAsBytes();
          final uploaded = await ref.read(chatRepositoryProvider).uploadAttachment(
            bytes,
            f.name,
            mimeType: mime,
          );

          if (mounted) {
            setState(() {
              _pendingAttachments.add({
                'upload_id': uploaded.id,
                'file_path': uploaded.filePath,
                'file_name': uploaded.fileName,
                'file_size': uploaded.fileSize,
                'mime_type': uploaded.mimeType,
              });
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to select or upload attachment.');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty && _selectedTask == null) return;

    setState(() => _isSending = true);
    final atts = List<Map<String, dynamic>>.from(_pendingAttachments);
    final taskId = _selectedTask?.id;

    _messageController.clear();
    setState(() {
      _pendingAttachments = [];
      _selectedTask = null;
    });

    _typingDebounce?.cancel();
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      ref.read(chatRepositoryProvider).sendTyping(widget.conversationId, false);
    }

    try {
      await ref.read(chatRoomProvider(widget.conversationId).notifier).sendMessage(
        message: text.isNotEmpty ? text : null,
        taskId: taskId,
        attachments: atts.isNotEmpty ? atts : null,
      );
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to send message';
        if (e is ApiException) {
          if (e.statusCode == 403) {
            msg = 'You do not have permission to send messages here.';
          } else if (e.statusCode == 404) {
            msg = 'Conversation or resource not found.';
          } else if (e.statusCode == 413) {
            msg = 'Attachment exceeds the allowed size limit (20 MB).';
          } else if (e.statusCode == 422) {
            msg = e.message.isNotEmpty ? e.message : 'Validation failed. Please verify your input.';
          } else {
            msg = e.message;
          }
        } else {
          final s = e.toString().replaceFirst('Exception: ', '');
          if (s.contains('403')) {
            msg = 'You do not have permission to post in this chat.';
          } else if (s.contains('413')) {
            msg = 'File exceeds upload size limit (20 MB).';
          } else if (s.contains('422')) {
            msg = 'Invalid message or attachment.';
          } else {
            msg = s;
          }
        }
        AppToast.error(context, msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showActionMenu(BuildContext context, ConversationModel conv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.attach_file, color: Colors.white, size: 20),
                ),
                title: const Text('Pick Files from Device'),
                subtitle: const Text('Browse photos, documents, PDFs, zip'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDeviceFiles();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.emerald,
                  child: Icon(Icons.task_alt, color: Colors.white, size: 20),
                ),
                title: const Text('Link a Task'),
                subtitle: Text(conv.isProject ? 'Attach a task from this project' : 'Attach one of your tasks'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTaskPickerDialog(context, conv);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskPickerDialog(BuildContext context, ConversationModel conv) async {
    showDialog(
      context: context,
      builder: (dialogCtx) => Consumer(
        builder: (context, ref, _) {
          final repo = ref.read(taskRepositoryProvider);
          return FutureBuilder<List<TaskItem>>(
            future: conv.projectId != null
                ? repo.getProjectTasks(conv.projectId!)
                : repo.getMyTasks(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data ?? [];
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.task_alt, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(conv.projectId != null ? 'Link Project Task' : 'Link a Task'),
                  ],
                ),
                content: SizedBox(
                  width: 440,
                  child: tasks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No active tasks found.', textAlign: TextAlign.center),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: tasks.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final t = tasks[i];
                            return ListTile(
                              dense: true,
                              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${t.statusDisplay} • ${t.priorityDisplay}', style: const TextStyle(fontSize: 11)),
                              trailing: Icon(t.statusIcon, size: 16, color: t.statusColor),
                              onTap: () {
                                Navigator.pop(dialogCtx);
                                setState(() => _selectedTask = t);
                              },
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showConversationInfoDialog(BuildContext context, ConversationModel conv) {
    final currentUserId = ref.read(authControllerProvider).value?.id;
    final isGroupAdmin = conv.isGroup &&
        conv.participants.any((p) => p.userId == currentUserId && p.role == 'admin');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
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
              child: Text(
                conv.displayName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conv.isProject && conv.projectId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Channel: ${conv.projectName ?? "Project #${conv.projectId}"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (conv.projectCode != null)
                          Text('Code: ${conv.projectCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_browser, size: 16),
                          label: const Text('Open Project Workspace'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            context.push('/projects/${conv.projectId}');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Participants (${conv.participants.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isGroupAdmin)
                      TextButton.icon(
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add'),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _showAddParticipantDialog(context, conv);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: conv.participants.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final p = conv.participants[i];
                    final isSelf = p.userId == currentUserId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      title: Text(
                        '${p.name}${isSelf ? " (You)" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(p.role.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      trailing: (isGroupAdmin && !isSelf)
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.rose),
                              tooltip: 'Remove',
                              onPressed: () async {
                                Navigator.pop(dialogCtx);
                                try {
                                  await ref
                                      .read(chatRoomProvider(widget.conversationId).notifier)
                                      .removeParticipant(p.userId);
                                  if (context.mounted) {
                                    AppToast.success(context, 'Removed ${p.name}');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.error(context, 'Failed to remove: $e');
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (conv.isGroup)
            TextButton.icon(
              icon: const Icon(Icons.exit_to_app, color: AppColors.rose, size: 16),
              label: const Text('Leave Group', style: TextStyle(color: AppColors.rose)),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Leave Group?'),
                    content: const Text('Are you sure you want to leave this conversation?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && currentUserId != null) {
                  try {
                    await ref
                        .read(chatRoomProvider(widget.conversationId).notifier)
                        .removeParticipant(currentUserId);
                    if (context.mounted) {
                      context.pop();
                      AppToast.info(context, 'You left the group');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(context, 'Failed to leave group: $e');
                    }
                  }
                }
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddParticipantDialog(BuildContext context, ConversationModel conv) async {
    final existingIds = conv.participants.map((p) => p.userId).toSet();
    final employeesRes = await ref.read(employeeRepositoryProvider).getEmployees(isActive: true, perPage: 100);
    final available = employeesRes.items.where((e) => !existingIds.contains(e.id)).toList();

    if (!context.mounted) return;

    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Members to Group'),
          content: SizedBox(
            width: 400,
            child: available.isEmpty
                ? const Text('All active colleagues are already in this group.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: available.length,
                    itemBuilder: (_, i) {
                      final emp = available[i];
                      final isChecked = selected.contains(emp.id);
                      return CheckboxListTile(
                        value: isChecked,
                        dense: true,
                        title: Text(emp.name),
                        subtitle: Text(emp.departmentName),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selected.add(emp.id);
                            } else {
                              selected.remove(emp.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await ref
                            .read(chatRoomProvider(widget.conversationId).notifier)
                            .addParticipants(selected.toList());
                        if (context.mounted) {
                          AppToast.success(context, 'Added ${selected.length} members to group');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.error(context, 'Failed to add members: $e');
                        }
                      }
                    },
              child: Text('Add (${selected.length})'),
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
    final presence = ref.watch(presenceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: chatStateAsync.when(
          data: (state) {
            final conv = state.conversation;
            final partnerId = conv.partnerId ??
                (conv.participants.where((p) => p.userId != currentUser?.id).firstOrNull?.userId);
            final isPartnerOnline = conv.isDirect && partnerId != null
                ? (presence.isUserOnline(partnerId) || conv.partnerIsOnline == true)
                : false;
            final partnerPresenceText = partnerId != null ? presence.formatPresence(partnerId) : 'Offline';

            return InkWell(
              onTap: () => _showConversationInfoDialog(context, conv),
              child: Row(
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
                        if (state.isPartnerTyping)
                          Row(
                            children: [
                              Text(
                                '${state.partnerTypingName ?? "Someone"} is typing',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.emerald),
                              ),
                            ],
                          )
                        else if (conv.isDirect)
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isPartnerOnline ? AppColors.emerald : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isPartnerOnline ? 'Online' : partnerPresenceText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPartnerOnline ? AppColors.emerald : Colors.grey,
                                  fontWeight: isPartnerOnline ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            conv.isGroup
                                ? '${conv.participants.length} members • Tap for details'
                                : 'Project Discussion • Tap for details',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Text('Loading chat...'),
          error: (_, _) => const Text('Chat Room'),
        ),
        actions: [
          chatStateAsync.when(
            data: (state) => IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Conversation Info',
              onPressed: () => _showConversationInfoDialog(context, state.conversation),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
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

            // Pending Task Link Bar
            if (_selectedTask != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Linked Task: ${_selectedTask!.title} (#${_selectedTask!.id})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selectedTask = null),
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

            // Mention Suggestions Popup
            if (_mentionSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mentionSuggestions.length,
                  itemBuilder: (context, idx) {
                    final p = _mentionSuggestions[idx];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(p.role, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      onTap: () => _insertMention(p),
                    );
                  },
                ),
              ),

            // Live Partner Typing Banner
            if (state.isPartnerTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  border: Border(top: BorderSide(color: AppColors.emerald.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.partnerTypingName ?? "Someone"} is typing...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w500,
                      ),
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
                      tooltip: 'Attach or Link',
                      onPressed: () => _showActionMenu(context, state.conversation),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: (text) => _onTextChanged(text, state.conversation),
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

                    // Linked Task Badge (clickable to view TaskDetailDialog)
                    if (message.hasTaskLink)
                      InkWell(
                        onTap: () {
                          if (message.taskId != null) {
                            showDialog(
                              context: context,
                              builder: (_) => TaskDetailDialog(taskId: message.taskId!),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
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
                                    decoration: TextDecoration.underline,
                                    decorationColor: isSelf ? Colors.white70 : AppColors.primary,
                                    color: isSelf ? Colors.white : AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new,
                                size: 12,
                                color: (isSelf ? Colors.white : AppColors.primary).withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Attachments Cards & Inline Images
                    if (message.hasAttachments)
                      ...message.attachments.map((att) => _buildAttachmentCard(context, att, isSelf)),

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

  Widget _buildAttachmentCard(BuildContext context, ChatAttachmentModel att, bool isSelf) {
    if (att.isImage && att.url.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(context, att.url, att.fileName),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (isSelf ? Colors.white : AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Image.network(
                  att.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, color: Colors.grey.shade600, size: 28),
                          const SizedBox(height: 4),
                          Text(att.fileName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 100,
                      color: (isSelf ? Colors.black12 : Colors.grey.shade100),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            att.fileName,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          att.formattedSize,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        if (att.url.isNotEmpty) {
          if (att.isImage) {
            _showFullScreenImage(context, att.url, att.fileName);
          } else {
            await FileDownloadService.downloadFile(
              context: context,
              rawUrl: att.url,
              fileName: att.fileName,
              autoOpen: true,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(Icons.download, size: 18, color: isSelf ? Colors.white70 : AppColors.textMuted),
              tooltip: 'Save to Downloads',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              onPressed: () => FileDownloadService.downloadFile(
                context: context,
                rawUrl: att.url,
                fileName: att.fileName,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(title, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.download, color: Colors.white, size: 20),
                      tooltip: 'Save to Downloads',
                      onPressed: () => FileDownloadService.downloadFile(
                        context: context,
                        rawUrl: url,
                        fileName: title,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
