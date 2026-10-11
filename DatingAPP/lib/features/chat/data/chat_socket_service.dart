import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'chat_api.dart';

class ChatSocketService {
  ChatSocketService(this.api);

  final ChatApi api;
  final StreamController<Map<String, dynamic>> _newMessages =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageErrors =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _sentMessages =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _readReceipts =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _reconnections =
      StreamController<void>.broadcast();
  final StreamController<bool> _connectionStates =
      StreamController<bool>.broadcast();
  socket_io.Socket? _socket;
  Completer<void>? _connectionCompleter;
  Completer<void>? _joinCompleter;
  String? _activeConversationId;
  String? currentUserId;
  bool _connectedBefore = false;
  bool _rejoinAfterReconnect = false;
  bool _disposed = false;
  bool _ready = false;

  bool get ready => !_disposed && _ready && _socket?.connected == true;

  Stream<Map<String, dynamic>> get newMessages => _newMessages.stream;
  Stream<Map<String, dynamic>> get messageErrors => _messageErrors.stream;
  Stream<Map<String, dynamic>> get sentMessages => _sentMessages.stream;
  Stream<Map<String, dynamic>> get readReceipts => _readReceipts.stream;
  Stream<void> get reconnections => _reconnections.stream;
  Stream<bool> get connectionStates => _connectionStates.stream;

  Future<void> connect() async {
    if (_disposed) throw StateError('Chat screen closed.');
    if (ready) return;
    final existingConnection = _connectionCompleter;
    if (existingConnection != null) return existingConnection.future;

    final completer = Completer<void>();
    // Disposal can complete this while the token request is still pending.
    unawaited(completer.future.then<void>((_) {}, onError: (Object _) {}));
    _connectionCompleter = completer;
    try {
      if (_disposed) throw StateError('Chat screen closed.');
      final baseUri = Uri.parse(api.baseUrl);
      final socketOrigin = baseUri
          .replace(path: '', query: null, fragment: null)
          .toString();
      _socket?.dispose();
      _ready = false;
      currentUserId = null;
      final socket = socket_io.io(socketOrigin, {
        'transports': ['websocket'],
        'autoConnect': false,
        // The default manager cache is keyed by origin, not account. Each chat
        // must own its connection so a previous account's auth cannot survive.
        'forceNew': true,
        'multiplex': false,
      });
      _socket = socket;
      socket.auth = (Function callback) async {
        try {
          final freshToken = await api.getSessionToken().timeout(
            const Duration(seconds: 10),
          );
          if (!_disposed && identical(_socket, socket)) {
            callback({'token': freshToken});
          }
        } catch (error) {
          if (!completer.isCompleted) completer.completeError(error);
          socket.disconnect();
        }
      };
      socket.on('chat:ready', (data) {
        if (_disposed || !identical(_socket, socket)) return;
        currentUserId = data is Map ? data['userId']?.toString() : null;
        _ready = true;
        _connectionStates.add(true);
        _rejoinAfterReconnect = _connectedBefore;
        _connectedBefore = true;
        final conversationId = _activeConversationId;
        if (conversationId != null) {
          socket.emit('conversation:join', {'conversationId': conversationId});
        } else if (_rejoinAfterReconnect) {
          _reconnections.add(null);
          _rejoinAfterReconnect = false;
        }
        if (!completer.isCompleted) completer.complete();
        _connectionCompleter = null;
      });
      socket.on('conversation:joined', (data) {
        if (data is! Map || data['conversationId'] != _activeConversationId) {
          return;
        }
        final joinCompleter = _joinCompleter;
        if (joinCompleter != null && !joinCompleter.isCompleted) {
          joinCompleter.complete();
        }
        _joinCompleter = null;
        // Refresh history after every join, including the first one, to cover
        // messages sent between the initial HTTP request and joining the room.
        _reconnections.add(null);
        _rejoinAfterReconnect = false;
      });
      socket.on('chat:error', (data) {
        final joinCompleter = _joinCompleter;
        if (joinCompleter != null && !joinCompleter.isCompleted) {
          joinCompleter.completeError(
            StateError(data is Map ? '${data['message']}' : 'Chat error.'),
          );
          _joinCompleter = null;
        }
      });
      socket.onConnectError((error) {
        if (!_disposed) _connectionStates.add(false);
        if (!completer.isCompleted) {
          completer.completeError(StateError('Chat connection failed: $error'));
        }
        _connectionCompleter = null;
      });
      socket.onDisconnect((_) {
        _ready = false;
        if (!_disposed) _connectionStates.add(false);
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Chat disconnected before authentication.'),
          );
        }
        final joining = _joinCompleter;
        if (joining != null && !joining.isCompleted) {
          joining.completeError(StateError('Chat disconnected.'));
        }
        _joinCompleter = null;
      });
      socket.on('message:new', (data) {
        if (data is Map) {
          _newMessages.add(Map<String, dynamic>.from(data));
        }
      });
      socket.on('message:error', (data) {
        if (data is Map) {
          _messageErrors.add(Map<String, dynamic>.from(data));
        }
      });
      socket.on('message:sent', (data) {
        if (data is Map) {
          _sentMessages.add(Map<String, dynamic>.from(data));
        }
      });
      socket.on('conversation:read', (data) {
        if (data is Map) {
          _readReceipts.add(Map<String, dynamic>.from(data));
        }
      });
      socket.connect();
      await completer.future.timeout(const Duration(seconds: 20));
    } catch (error) {
      _ready = false;
      _socket?.dispose();
      _socket = null;
      rethrow;
    } finally {
      if (identical(_connectionCompleter, completer)) {
        _connectionCompleter = null;
      }
    }
  }

  Future<void> joinConversation(String conversationId) async {
    final joining = _joinCompleter;
    if (joining != null && _activeConversationId == conversationId) {
      return joining.future;
    }
    _activeConversationId = conversationId;
    final socket = _socket;
    if (!ready) {
      throw StateError('Chat is not connected.');
    }
    final completer = Completer<void>();
    _joinCompleter = completer;
    socket!.emit('conversation:join', {'conversationId': conversationId});
    try {
      await completer.future.timeout(const Duration(seconds: 10));
    } finally {
      if (identical(_joinCompleter, completer)) _joinCompleter = null;
    }
  }

  void sendText({
    required String conversationId,
    required String clientMessageId,
    required String text,
  }) {
    sendMessage({
      'conversationId': conversationId,
      'clientMessageId': clientMessageId,
      'text': text,
      'type': 'text',
    });
  }

  void sendMessage(Map<String, dynamic> payload) {
    final socket = _socket;
    if (!ready) {
      throw StateError('Chat is offline. Reconnect and retry your message.');
    }
    socket!.emit('message:send', payload);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _ready = false;
    final connectionCompleter = _connectionCompleter;
    if (connectionCompleter != null && !connectionCompleter.isCompleted) {
      connectionCompleter.completeError(StateError('Chat screen closed.'));
    }
    final joinCompleter = _joinCompleter;
    if (joinCompleter != null && !joinCompleter.isCompleted) {
      joinCompleter.completeError(StateError('Chat screen closed.'));
    }
    final socket = _socket;
    _socket = null;
    socket?.disconnect();
    socket?.dispose();
    await _newMessages.close();
    await _messageErrors.close();
    await _sentMessages.close();
    await _readReceipts.close();
    await _reconnections.close();
    await _connectionStates.close();
  }
}
