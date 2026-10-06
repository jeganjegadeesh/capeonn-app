import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../../../core/config/app_config.dart';
import 'chat_models.dart';

/// Connection status enum for WebSocket transport
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Typing indicator payload received over WebSocket
class ChatUserTypingData {
  const ChatUserTypingData({
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.isTyping,
  });

  final int conversationId;
  final int userId;
  final String userName;
  final bool isTyping;

  factory ChatUserTypingData.fromJson(Map<String, dynamic> json) {
    return ChatUserTypingData(
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String? ?? 'Someone',
      isTyping: json['is_typing'] as bool? ?? false,
    );
  }
}

/// Message read receipt payload received over WebSocket
class ChatMessageReadData {
  const ChatMessageReadData({
    required this.conversationId,
    required this.userId,
    required this.userName,
    this.lastReadMessageId,
    this.readAt,
  });

  final int conversationId;
  final int userId;
  final String userName;
  final int? lastReadMessageId;
  final String? readAt;

  factory ChatMessageReadData.fromJson(Map<String, dynamic> json) {
    return ChatMessageReadData(
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String? ?? '',
      lastReadMessageId: (json['last_read_message_id'] as num?)?.toInt(),
      readAt: json['read_at'] as String?,
    );
  }
}

class _ConversationSubscriptions {
  _ConversationSubscriptions({
    required this.channel,
    required this.subscriptions,
  });

  final PrivateChannel channel;
  final List<StreamSubscription<dynamic>> subscriptions;

  Future<void> cancelAll() async {
    for (final s in subscriptions) {
      await s.cancel();
    }
    channel.unsubscribe();
  }
}

/// Real-time WebSocket Client Transport (Pusher / Soketi Compatible)
/// Provides pure Dart real-time messaging, typing indicators, and read receipts
/// across Web, Mobile, and Desktop platforms.
class ChatWebSocketService {
  ChatWebSocketService();

  PusherChannelsClient? _client;
  WebSocketStatus _status = WebSocketStatus.disconnected;

  final StreamController<WebSocketStatus> _statusController =
      StreamController<WebSocketStatus>.broadcast();
  final StreamController<ChatMessageModel> _messageController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<ChatUserTypingData> _typingController =
      StreamController<ChatUserTypingData>.broadcast();
  final StreamController<ChatMessageReadData> _readReceiptController =
      StreamController<ChatMessageReadData>.broadcast();
  final StreamController<UserPresenceModel> _presenceController =
      StreamController<UserPresenceModel>.broadcast();

  final Map<int, _ConversationSubscriptions> _activeChannels = {};
  final Map<int, _ConversationSubscriptions> _companyChannels = {};

  StreamSubscription<dynamic>? _lifecycleSub;

  WebSocketStatus get status => _status;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<ChatUserTypingData> get typingStream => _typingController.stream;
  Stream<ChatMessageReadData> get readReceiptStream =>
      _readReceiptController.stream;
  Stream<UserPresenceModel> get presenceStream => _presenceController.stream;

  void _setStatus(WebSocketStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Initialize and connect to the Pusher/Soketi WebSocket server
  Future<void> connect({
    required String authToken,
    String? host,
    int? port,
    String? scheme,
    String? key,
  }) async {
    if (_status == WebSocketStatus.connected ||
        _status == WebSocketStatus.connecting) {
      return;
    }

    try {
      _setStatus(WebSocketStatus.connecting);

      final wsHost = host ?? AppConfig.wsHost;
      final wsPort = port ?? AppConfig.wsPort;
      final wsScheme = scheme ?? AppConfig.wsScheme;
      final wsKey = key ?? AppConfig.wsKey;

      final options = PusherChannelsOptions.fromHost(
        scheme: wsScheme,
        host: wsHost,
        port: wsPort,
        key: wsKey,
      );

      _client = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (error, trace, refresh) {
          debugPrint('WebSocket error: $error');
          _setStatus(WebSocketStatus.error);
        },
      );

      _lifecycleSub?.cancel();
      _lifecycleSub = _client!.lifecycleStream.listen((event) {
        // Lifecycle events reflect state changes
        final eventStr = event.toString().toLowerCase();
        if (eventStr.contains('connected') || eventStr.contains('established')) {
          _setStatus(WebSocketStatus.connected);
        } else if (eventStr.contains('disconnect') || eventStr.contains('closed')) {
          _setStatus(WebSocketStatus.disconnected);
        } else if (eventStr.contains('reconnecting')) {
          _setStatus(WebSocketStatus.reconnecting);
        }
      });

      _client!.connect();
      // Assume connected once connect() initiates without throwing
      _setStatus(WebSocketStatus.connected);
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _setStatus(WebSocketStatus.error);
    }
  }

  /// Subscribe to a private conversation channel for real-time events
  void subscribeConversation(
    int conversationId, {
    required String authToken,
    String? authEndpoint,
  }) {
    if (_client == null || _activeChannels.containsKey(conversationId)) {
      return;
    }

    try {
      final endpoint = authEndpoint ?? AppConfig.wsAuthUrl;
      final channelName = 'private-conversation.$conversationId';

      final channel = _client!.privateChannel(
        channelName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        ),
      );

      final subs = <StreamSubscription<dynamic>>[];

      // 1. Bind message.sent
      final messageBind = channel.bind('message.sent');
      final messageSub = messageBind.listen((ChannelReadEvent event) {
        try {
          final map = _decodeData(event.data);
          if (map != null && map.containsKey('message')) {
            final msgMap = map['message'];
            if (msgMap is Map<String, dynamic>) {
              final model = ChatMessageModel.fromJson(msgMap);
              _messageController.add(model);
            }
          }
        } catch (e) {
          debugPrint('Error parsing message.sent: $e');
        }
      });
      subs.add(messageSub);

      // 2. Bind user.typing
      final typingBind = channel.bind('user.typing');
      final typingSub = typingBind.listen((ChannelReadEvent event) {
        try {
          final map = _decodeData(event.data);
          if (map != null) {
            final typingData = ChatUserTypingData.fromJson(map);
            _typingController.add(typingData);
          }
        } catch (e) {
          debugPrint('Error parsing user.typing: $e');
        }
      });
      subs.add(typingSub);

      // 3. Bind message.read
      final readBind = channel.bind('message.read');
      final readSub = readBind.listen((ChannelReadEvent event) {
        try {
          final map = _decodeData(event.data);
          if (map != null) {
            final readData = ChatMessageReadData.fromJson(map);
            _readReceiptController.add(readData);
          }
        } catch (e) {
          debugPrint('Error parsing message.read: $e');
        }
      });
      subs.add(readSub);

      channel.subscribeIfNotUnsubscribed();

      _activeChannels[conversationId] = _ConversationSubscriptions(
        channel: channel,
        subscriptions: subs,
      );
    } catch (e) {
      debugPrint('Failed to subscribe to conversation $conversationId: $e');
    }
  }

  /// Unsubscribe from a conversation channel
  Future<void> unsubscribeConversation(int conversationId) async {
    final entry = _activeChannels.remove(conversationId);
    if (entry != null) {
      await entry.cancelAll();
    }
  }

  /// Subscribe to company-wide channel for presence heartbeat updates
  void subscribeCompany(
    int companyId, {
    required String authToken,
    String? authEndpoint,
  }) {
    if (_client == null || _companyChannels.containsKey(companyId)) {
      return;
    }

    try {
      final endpoint = authEndpoint ?? AppConfig.wsAuthUrl;
      final channelName = 'private-company.$companyId';

      final channel = _client!.privateChannel(
        channelName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        ),
      );

      final subs = <StreamSubscription<dynamic>>[];

      // Bind user.presence
      final presenceBind = channel.bind('user.presence');
      final presenceSub = presenceBind.listen((ChannelReadEvent event) {
        try {
          final map = _decodeData(event.data);
          if (map != null) {
            final presenceData = UserPresenceModel.fromJson(map);
            _presenceController.add(presenceData);
          }
        } catch (e) {
          debugPrint('Error parsing user.presence: $e');
        }
      });
      subs.add(presenceSub);

      channel.subscribeIfNotUnsubscribed();

      _companyChannels[companyId] = _ConversationSubscriptions(
        channel: channel,
        subscriptions: subs,
      );
    } catch (e) {
      debugPrint('Failed to subscribe to company channel $companyId: $e');
    }
  }

  /// Unsubscribe from company channel
  Future<void> unsubscribeCompany(int companyId) async {
    final entry = _companyChannels.remove(companyId);
    if (entry != null) {
      await entry.cancelAll();
    }
  }

  /// Disconnect all channels and close client connection
  Future<void> disconnect() async {
    for (final entry in _activeChannels.values) {
      await entry.cancelAll();
    }
    _activeChannels.clear();

    for (final entry in _companyChannels.values) {
      await entry.cancelAll();
    }
    _companyChannels.clear();

    await _lifecycleSub?.cancel();
    _lifecycleSub = null;

    if (_client != null) {
      try {
        _client!.disconnect();
      } catch (_) {}
      _client = null;
    }

    _setStatus(WebSocketStatus.disconnected);
  }

  /// Helper to safely decode event payload
  Map<String, dynamic>? _decodeData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Dispose service controllers
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _messageController.close();
    await _typingController.close();
    await _readReceiptController.close();
    await _presenceController.close();
  }
}

/// Global provider for ChatWebSocketService
final chatWebSocketServiceProvider = Provider<ChatWebSocketService>((ref) {
  final service = ChatWebSocketService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Current WebSocket connection status provider
final webSocketStatusProvider = StreamProvider<WebSocketStatus>((ref) {
  final service = ref.watch(chatWebSocketServiceProvider);
  return service.statusStream;
});
