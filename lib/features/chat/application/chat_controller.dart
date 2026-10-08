import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_models.dart';
import '../data/chat_repository.dart';
import '../data/chat_websocket_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/network/api_client.dart';

/// Filter state for conversations list
class ConversationsFilter {
  const ConversationsFilter({this.search = '', this.type = 'all'});

  final String search;
  final String type; // all, direct, group, project

  ConversationsFilter copyWith({String? search, String? type}) {
    return ConversationsFilter(
      search: search ?? this.search,
      type: type ?? this.type,
    );
  }
}

class ConversationsFilterNotifier extends Notifier<ConversationsFilter> {
  @override
  ConversationsFilter build() => const ConversationsFilter();

  @override
  set state(ConversationsFilter value) => super.state = value;
  void setFilter(ConversationsFilter filter) => state = filter;
}

final conversationsFilterProvider =
    NotifierProvider<ConversationsFilterNotifier, ConversationsFilter>(
  ConversationsFilterNotifier.new,
);

/// Unread messages count provider with periodic refresh
final chatUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  final count = await repo.getUnreadSummary();

  // Refresh every 20 seconds while app is running
  final timer = Timer(const Duration(seconds: 20), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return count;
});

/// Conversations list provider
final conversationsListProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  final filter = ref.watch(conversationsFilterProvider);

  final list = await repo.getConversations(
    search: filter.search.isNotEmpty ? filter.search : null,
    type: filter.type != 'all' ? filter.type : null,
  );

  // Auto-refresh every 12 seconds in list view
  final timer = Timer(const Duration(seconds: 12), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return list;
});

/// Active chat room state
class ChatRoomState {
  const ChatRoomState({
    required this.conversation,
    required this.messages,
    this.isLoadingOlder = false,
    this.hasMoreOlder = true,
    this.replyingTo,
    this.isPartnerTyping = false,
    this.partnerTypingName,
  });

  final ConversationModel conversation;
  final List<ChatMessageModel> messages;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final ChatMessageModel? replyingTo;
  final bool isPartnerTyping;
  final String? partnerTypingName;

  ChatRoomState copyWith({
    ConversationModel? conversation,
    List<ChatMessageModel>? messages,
    bool? isLoadingOlder,
    bool? hasMoreOlder,
    ChatMessageModel? replyingTo,
    bool clearReply = false,
    bool? isPartnerTyping,
    String? partnerTypingName,
  }) {
    return ChatRoomState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      partnerTypingName: partnerTypingName ?? this.partnerTypingName,
    );
  }
}

/// Active chat room notifier with dual-mode real-time sync (WebSocket primary + fallback polling)
class ChatRoomNotifier extends AsyncNotifier<ChatRoomState> {
  ChatRoomNotifier(this.conversationId);

  final int conversationId;
  Timer? _pollingTimer;
  StreamSubscription<ChatMessageModel>? _wsMessageSub;
  StreamSubscription<ChatUserTypingData>? _wsTypingSub;
  StreamSubscription<ChatMessageReadData>? _wsReadSub;
  StreamSubscription<ChatMessageDeletedData>? _wsDeletedSub;
  StreamSubscription<ChatMessageModel>? _wsUpdatedSub;
  StreamSubscription<ChatMessagePinnedData>? _wsPinnedSub;
  Timer? _typingResetTimer;

  @override
  Future<ChatRoomState> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    final conv = await repo.getConversation(conversationId);
    final messages = await repo.getMessages(conversationId, perPage: 40);

    // 1. Dual-mode sync: Fallback polling every 4 seconds in background
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _syncLatest());

    // 2. WebSocket real-time transport: Connect and subscribe to conversation
    _initWebSocket();

    ref.onDispose(() {
      _pollingTimer?.cancel();
      _typingResetTimer?.cancel();
      _wsMessageSub?.cancel();
      _wsTypingSub?.cancel();
      _wsReadSub?.cancel();
      _wsDeletedSub?.cancel();
      _wsUpdatedSub?.cancel();
      _wsPinnedSub?.cancel();
      final ws = ref.read(chatWebSocketServiceProvider);
      unawaited(ws.unsubscribeConversation(conversationId));
    });

    // Mark as read
    unawaited(repo.markAsRead(conversationId));
    ref.invalidate(chatUnreadCountProvider);

    return ChatRoomState(
      conversation: conv,
      messages: messages,
      hasMoreOlder: messages.length >= 40,
    );
  }

  Future<void> _initWebSocket() async {
    try {
      final token = await ref.read(tokenStorageProvider).read();
      if (token == null || token.isEmpty) return;

      final ws = ref.read(chatWebSocketServiceProvider);
      await ws.connect(authToken: token);
      ws.subscribeConversation(conversationId, authToken: token);

      // Listen for real-time messages
      _wsMessageSub?.cancel();
      _wsMessageSub = ws.messageStream.listen((msg) {
        if (msg.conversationId == conversationId) {
          _handleIncomingMessage(msg);
        }
      });

      // Listen for typing events
      _wsTypingSub?.cancel();
      _wsTypingSub = ws.typingStream.listen((typing) {
        if (typing.conversationId == conversationId) {
          _handleIncomingTyping(typing);
        }
      });

      // Listen for read receipts
      _wsReadSub?.cancel();
      _wsReadSub = ws.readReceiptStream.listen((readReceipt) {
        if (readReceipt.conversationId == conversationId) {
          _handleIncomingReadReceipt(readReceipt);
        }
      });

      // Listen for deleted messages
      _wsDeletedSub?.cancel();
      _wsDeletedSub = ws.messageDeletedStream.listen((deleted) {
        if (deleted.conversationId == conversationId) {
          _handleIncomingDeleted(deleted);
        }
      });

      // Listen for edited messages
      _wsUpdatedSub?.cancel();
      _wsUpdatedSub = ws.messageUpdatedStream.listen((updatedMsg) {
        if (updatedMsg.conversationId == conversationId) {
          _handleIncomingUpdated(updatedMsg);
        }
      });

      // Listen for pinned messages
      _wsPinnedSub?.cancel();
      _wsPinnedSub = ws.messagePinnedStream.listen((pinned) {
        if (pinned.message.conversationId == conversationId) {
          _handleIncomingPinned(pinned);
        }
      });
    } catch (_) {
      // Gracefully fall back to background polling on connection issues
    }
  }

  void _handleIncomingDeleted(ChatMessageDeletedData data) {
    final current = state.value;
    if (current == null) return;
    final updated = current.messages.where((m) => m.id != data.messageId).toList();
    state = AsyncData(current.copyWith(messages: updated));
  }

  void _handleIncomingUpdated(ChatMessageModel updatedMsg) {
    final current = state.value;
    if (current == null) return;
    final updated = current.messages.map((m) => m.id == updatedMsg.id ? updatedMsg : m).toList();
    state = AsyncData(current.copyWith(messages: updated));
  }

  void _handleIncomingPinned(ChatMessagePinnedData data) {
    final current = state.value;
    if (current == null) return;
    final updated = current.messages.map((m) {
      if (m.id == data.message.id) {
        return m.copyWith(isPinned: data.isPinned);
      }
      return m;
    }).toList();
    state = AsyncData(current.copyWith(messages: updated));
  }

  void _handleIncomingMessage(ChatMessageModel msg) {
    final current = state.value;
    if (current == null) return;
    if (current.messages.any((m) => m.id == msg.id)) return;

    final updated = <ChatMessageModel>[msg, ...current.messages];
    state = AsyncData(current.copyWith(
      messages: updated,
      isPartnerTyping: false,
    ));

    final repo = ref.read(chatRepositoryProvider);
    unawaited(repo.markAsRead(conversationId));
    ref.invalidate(chatUnreadCountProvider);
    ref.invalidate(conversationsListProvider);
  }

  void _handleIncomingTyping(ChatUserTypingData typing) {
    final current = state.value;
    if (current == null) return;

    // Ignore typing events generated by current user so they never see their own typing banner
    final currentUserId = ref.read(authControllerProvider).value?.id;
    if (currentUserId != null && typing.userId == currentUserId) {
      return;
    }

    _typingResetTimer?.cancel();
    if (typing.isTyping) {
      state = AsyncData(current.copyWith(
        isPartnerTyping: true,
        partnerTypingName: typing.userName,
      ));
      // Auto-clear typing indicator after 3 seconds of inactivity
      _typingResetTimer = Timer(const Duration(seconds: 3), () {
        final s = state.value;
        if (s != null && s.isPartnerTyping) {
          state = AsyncData(s.copyWith(isPartnerTyping: false));
        }
      });
    } else {
      state = AsyncData(current.copyWith(isPartnerTyping: false));
    }
  }

  void _handleIncomingReadReceipt(ChatMessageReadData receipt) {
    ref.invalidate(chatUnreadCountProvider);
  }

  Future<void> sendTyping(bool isTyping) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendTyping(conversationId, isTyping);
    } catch (_) {}
  }

  Future<void> _syncLatest() async {
    final current = state.value;
    if (current == null) return;

    try {
      final repo = ref.read(chatRepositoryProvider);
      final latest = await repo.getMessages(conversationId, perPage: 20);
      if (latest.isNotEmpty) {
        final nowCurrent = state.value ?? current;
        final existingIds = nowCurrent.messages.map((m) => m.id).toSet();
        final newMessages = latest.where((m) => !existingIds.contains(m.id)).toList();

        if (newMessages.isNotEmpty) {
          // Merge and sort descending
          final merged = <ChatMessageModel>[...newMessages, ...nowCurrent.messages];
          merged.sort((a, b) => b.id.compareTo(a.id));

          state = AsyncData(nowCurrent.copyWith(messages: merged));
          await repo.markAsRead(conversationId);
          ref.invalidate(chatUnreadCountProvider);
        }
      }

      // Dual-mode sync: check active partner typing status as fallback
      final typingData = await repo.getTyping(conversationId);
      if (typingData != null && typingData.isTyping) {
        _handleIncomingTyping(typingData);
      }
    } catch (_) {
      // Keep silent on transient background sync glitches
    }
  }

  void setReplyingTo(ChatMessageModel? message) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(replyingTo: message, clearReply: message == null));
  }

  Future<void> loadOlderMessages() async {
    final current = state.value;
    if (current == null || current.isLoadingOlder || !current.hasMoreOlder) return;

    final oldestId = current.messages.isNotEmpty ? current.messages.last.id : null;
    if (oldestId == null) return;

    state = AsyncData(current.copyWith(isLoadingOlder: true));

    try {
      final repo = ref.read(chatRepositoryProvider);
      final older = await repo.getMessages(conversationId, beforeId: oldestId, perPage: 30);

      final hasMore = older.length >= 30;
      final nowCurrent = state.value ?? current;
      final existingIds = nowCurrent.messages.map((m) => m.id).toSet();
      final added = older.where((m) => !existingIds.contains(m.id)).toList();

      final merged = <ChatMessageModel>[...nowCurrent.messages, ...added];
      merged.sort((a, b) => b.id.compareTo(a.id));

      state = AsyncData(nowCurrent.copyWith(
        messages: merged,
        isLoadingOlder: false,
        hasMoreOlder: hasMore,
      ));
    } catch (_) {
      final nowCurrent = state.value ?? current;
      state = AsyncData(nowCurrent.copyWith(isLoadingOlder: false));
    }
  }

  Future<void> sendMessage({
    String? message,
    int? taskId,
    List<Map<String, dynamic>>? attachments,
    List<int>? mentions,
  }) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final replyId = current.replyingTo?.id;

    // Clear replying to immediately for smooth UX
    setReplyingTo(null);

    try {
      final sent = await repo.sendMessage(
        conversationId,
        message: message,
        replyToId: replyId,
        taskId: taskId,
        attachments: attachments,
        mentions: mentions,
      );

      // Optimistically update list with latest state and ensure reply stays cleared
      final latest = state.value ?? current;
      final updated = <ChatMessageModel>[
        sent,
        ...latest.messages.where((m) => m.id != sent.id),
      ];
      state = AsyncData(latest.copyWith(
        messages: updated,
        clearReply: true,
      ));

      ref.invalidate(conversationsListProvider);
      ref.invalidate(chatUnreadCountProvider);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> editMessage(int messageId, String newText, {List<int>? mentions}) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final updated = await repo.editMessage(conversationId, messageId, newText, mentions: mentions);

    final list = current.messages.map((m) => m.id == messageId ? updated : m).toList();
    state = AsyncData(current.copyWith(messages: list));
  }

  Future<void> togglePinMessage(int messageId) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final updated = await repo.pinMessage(conversationId, messageId);

    final list = current.messages.map((m) => m.id == messageId ? updated : m).toList();
    state = AsyncData(current.copyWith(messages: list));
  }

  Future<void> deleteMessage(int messageId) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    await repo.deleteMessage(conversationId, messageId);

    final updated = current.messages.where((m) => m.id != messageId).toList();
    state = AsyncData(current.copyWith(messages: updated));
  }

  Future<void> addParticipants(List<int> userIds) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final updated = await repo.addParticipants(conversationId, userIds);
    state = AsyncData(current.copyWith(conversation: updated));
    ref.invalidate(conversationsListProvider);
  }

  Future<void> removeParticipant(int userId) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    await repo.removeParticipant(conversationId, userId);
    final updatedConv = await repo.getConversation(conversationId);
    state = AsyncData(current.copyWith(conversation: updatedConv));
    ref.invalidate(conversationsListProvider);
  }

  Future<void> updateGroupSettings({
    String? title,
    String? description,
    int? avatarUploadId,
    String? avatarUrl,
    bool clearDescription = false,
    bool clearAvatar = false,
  }) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(chatRepositoryProvider);
    final updatedConv = await repo.updateConversation(
      conversationId,
      title: title,
      description: description,
      avatarUploadId: avatarUploadId,
      avatarUrl: avatarUrl,
      clearDescription: clearDescription,
      clearAvatar: clearAvatar,
    );
    state = AsyncData(current.copyWith(conversation: updatedConv));
    ref.invalidate(conversationsListProvider);
  }
}

final chatRoomProvider =
    AsyncNotifierProvider.family<ChatRoomNotifier, ChatRoomState, int>((conversationId) {
  return ChatRoomNotifier(conversationId);
});

/// Message search across conversations
final messageSearchResultsProvider =
    FutureProvider.autoDispose.family<List<ChatMessageModel>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final repo = ref.watch(chatRepositoryProvider);
  return repo.searchMessages(query.trim());
});
