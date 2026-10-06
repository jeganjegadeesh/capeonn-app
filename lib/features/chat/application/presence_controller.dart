import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/chat_models.dart';
import '../data/chat_websocket_service.dart';
import '../data/presence_repository.dart';

class PresenceState {
  const PresenceState({
    this.users = const {},
    this.isSelfOnline = false,
    this.lastHeartbeatAt,
  });

  final Map<int, UserPresenceModel> users;
  final bool isSelfOnline;
  final DateTime? lastHeartbeatAt;

  bool isUserOnline(int userId) {
    final entry = users[userId];
    if (entry == null) return false;
    return entry.isOnline;
  }

  DateTime? lastSeenAt(int userId) {
    return users[userId]?.lastSeenAt;
  }

  String formatPresence(int userId) {
    final entry = users[userId];
    if (entry == null) return 'Offline';
    if (entry.isOnline) return 'Online';
    if (entry.lastSeenAt == null) return 'Offline';

    final diff = DateTime.now().difference(entry.lastSeenAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Offline';
  }

  PresenceState copyWith({
    Map<int, UserPresenceModel>? users,
    bool? isSelfOnline,
    DateTime? lastHeartbeatAt,
  }) {
    return PresenceState(
      users: users ?? this.users,
      isSelfOnline: isSelfOnline ?? this.isSelfOnline,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
    );
  }
}

class PresenceNotifier extends Notifier<PresenceState> with WidgetsBindingObserver {
  Timer? _heartbeatTimer;
  StreamSubscription<UserPresenceModel>? _presenceSub;

  @override
  PresenceState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _heartbeatTimer?.cancel();
      _presenceSub?.cancel();
    });

    _initPresence();

    return const PresenceState();
  }

  Future<void> _initPresence() async {
    // 1. Listen for real-time presence changes from WebSocket
    final ws = ref.read(chatWebSocketServiceProvider);
    _presenceSub?.cancel();
    _presenceSub = ws.presenceStream.listen((event) {
      updatePresence(event);
    });

    // 2. Connect to company presence channel if user authenticated
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final companyId = user?.companyId ?? 1;
    if (user != null && companyId > 0) {
      final token = await ref.read(tokenStorageProvider).read();
      if (token != null && token.isNotEmpty) {
        await ws.connect(authToken: token);
        ws.subscribeCompany(companyId, authToken: token);
      }
    }

    // 3. Immediately send first heartbeat
    await sendHeartbeat();

    // 4. Setup periodic heartbeat timer (every 45 seconds)
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      sendHeartbeat();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sendHeartbeat();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached) {
      sendOffline();
    }
  }

  /// Sends presence heartbeat to backend
  Future<void> sendHeartbeat() async {
    final authState = ref.read(authControllerProvider);
    if (authState.value == null) return;

    try {
      final repo = ref.read(presenceRepositoryProvider);
      final result = await repo.sendHeartbeat();
      state = state.copyWith(
        isSelfOnline: true,
        lastHeartbeatAt: DateTime.now(),
        users: {
          ...state.users,
          result.userId: result,
        },
      );
    } catch (_) {
      // Keep silent on transient network errors
    }
  }

  /// Sends offline indicator to backend
  Future<void> sendOffline() async {
    final authState = ref.read(authControllerProvider);
    if (authState.value == null) return;

    try {
      final repo = ref.read(presenceRepositoryProvider);
      final result = await repo.sendOffline();
      state = state.copyWith(
        isSelfOnline: false,
        users: {
          ...state.users,
          result.userId: result,
        },
      );
    } catch (_) {}
  }

  /// Ingests live presence changes from WebSocket
  void updatePresence(UserPresenceModel presence) {
    final updated = Map<int, UserPresenceModel>.from(state.users);
    updated[presence.userId] = presence;
    state = state.copyWith(users: updated);
  }

  /// Ingests presence statuses from a conversation or colleague batch
  void seedPresences(List<UserPresenceModel> presences) {
    if (presences.isEmpty) return;
    final updated = Map<int, UserPresenceModel>.from(state.users);
    for (final p in presences) {
      updated[p.userId] = p;
    }
    state = state.copyWith(users: updated);
  }

  /// Explicitly query presence for a specific list of user IDs
  Future<void> fetchPresences(List<int> userIds) async {
    if (userIds.isEmpty) return;
    try {
      final repo = ref.read(presenceRepositoryProvider);
      final list = await repo.getPresence(userIds: userIds);
      seedPresences(list);
    } catch (_) {}
  }
}

final presenceProvider = NotifierProvider<PresenceNotifier, PresenceState>(
  PresenceNotifier.new,
);
