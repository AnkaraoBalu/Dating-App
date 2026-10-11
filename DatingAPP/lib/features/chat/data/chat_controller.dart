import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_models.dart';
import 'chat_api.dart';
import 'chat_socket_service.dart';

part 'chat_controller_events.dart';
part 'chat_controller_sending.dart';

class ChatController extends ChangeNotifier {
  ChatController({required this.api, required this.socket}) {
    _messageSubscription = socket.newMessages.listen(_receiveMessage);
    _errorSubscription = socket.messageErrors.listen(_receiveError);
    _sentSubscription = socket.sentMessages.listen(_confirmMessage);
    _readReceiptSubscription = socket.readReceipts.listen(_receiveReadReceipt);
    _reconnectSubscription = socket.reconnections.listen((_) {
      unawaited(_recoverAfterReconnect());
    });
    _connectionSubscription = socket.connectionStates.listen((connected) {
      connectionError = connected ? null : 'Live chat disconnected.';
      _notify();
    });
  }

  final ChatApi api;
  final ChatSocketService socket;
  final List<ChatMessage> messages = [];
  final Map<String, Timer> _sendTimeouts = {};
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _errorSubscription;
  StreamSubscription<Map<String, dynamic>>? _sentSubscription;
  StreamSubscription<Map<String, dynamic>>? _readReceiptSubscription;
  StreamSubscription<void>? _reconnectSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Future<void>? _openFuture;
  String? _knownConversationId;
  String? conversationId;
  String? _peerUserId;
  String? _oldestMessageId;
  bool loading = false;
  bool loadingOlder = false;
  bool hasMore = false;
  String? error;
  String? connectionError;
  bool _recovering = false;
  bool _reading = false;
  bool _readRequested = false;
  Map<String, dynamic>? _latestPeerReceipt;
  bool _disposed = false;
  bool active = true;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> open(String peerUserId, {String? existingConversationId}) {
    _knownConversationId = existingConversationId;
    return _openFuture ??= _open(peerUserId);
  }

  Future<void> retryOpen() {
    if (loading) return _openFuture ?? Future<void>.value();
    _openFuture = null;
    return open(
      _peerUserId ?? '',
      existingConversationId: _knownConversationId,
    );
  }

  Future<void> _open(String peerUserId) async {
    _peerUserId = peerUserId;
    loading = true;
    error = null;
    _notify();
    try {
      // These requests have no dependency on each other. Connect the socket
      // while the API creates/returns the conversation instead of making the
      // user wait for those network round trips sequentially.
      final connect = socket.connect().then(
        (_) => true,
        onError: (Object exception) {
          connectionError = exception.toString();
          _notify();
          return false;
        },
      );
      conversationId =
          _knownConversationId ?? await api.openConversation(peerUserId);
      if (_disposed) return;
      final id = conversationId!;
      unawaited(_joinLive(connect, id));

      // Load persisted messages without waiting for the socket handshake. Join
      // the room in the background once connected so first paint is not gated
      // by realtime setup.
      final historyOk = await _loadHistory();
      if (historyOk) unawaited(_markConversationRead(id));
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _joinLive(Future<bool> connected, String id) async {
    try {
      if (!await connected || _disposed) return;
      await socket.joinConversation(id);
      if (_disposed) return;
      connectionError = null;
      _notify();
    } catch (exception) {
      if (_disposed) return;
      connectionError = exception.toString();
      _notify();
    }
  }

  Future<void> retryConnection() async {
    final id = conversationId;
    if (id == null || _disposed) return;
    await _joinLive(
      socket.connect().then(
        (_) => true,
        onError: (Object exception) {
          connectionError = exception.toString();
          _notify();
          return false;
        },
      ),
      id,
    );
  }

  Future<bool> _loadHistory({String? recoverToId}) async {
    final id = conversationId;
    final peerId = _peerUserId;
    if (id == null || peerId == null) return false;
    try {
      var page = await api.loadMessages(conversationId: id, peerUserId: peerId);
      if (id != conversationId || _disposed) return false;
      final newestPage = page;
      while (true) {
        for (final message in page.items) {
          _merge(message);
        }
        if (recoverToId == null ||
            !page.hasMore ||
            page.items.any((message) => message.id == recoverToId)) {
          break;
        }
        final before = page.nextCursor;
        if (before == null || page.items.isEmpty) break;
        page = await api.loadMessages(
          conversationId: id,
          peerUserId: peerId,
          before: before,
        );
        if (_disposed || id != conversationId) return false;
      }
      page = newestPage;
      if (_oldestMessageId == null) {
        hasMore = page.hasMore;
        _oldestMessageId = page.items.isEmpty ? null : page.items.first.id;
      }
      error = null;
      _notify();
      return true;
    } catch (exception) {
      if (id != conversationId || _disposed) return false;
      error = exception.toString();
      _notify();
      return false;
    }
  }

  Future<void> loadOlder() async {
    final id = conversationId;
    final peerId = _peerUserId;
    final cursor = _oldestMessageId;
    if (id == null ||
        peerId == null ||
        cursor == null ||
        !hasMore ||
        loadingOlder) {
      return;
    }
    loadingOlder = true;
    _notify();
    try {
      final page = await api.loadMessages(
        conversationId: id,
        peerUserId: peerId,
        before: cursor,
      );
      if (id != conversationId || _disposed) return;
      for (final message in page.items) {
        _merge(message);
      }
      hasMore = page.hasMore;
      _oldestMessageId = page.items.isEmpty ? null : page.items.first.id;
      error = null;
    } catch (exception) {
      if (id == conversationId) error = exception.toString();
    } finally {
      loadingOlder = false;
      _notify();
    }
  }

  Future<void> _recoverAfterReconnect() async {
    if (_recovering || _disposed) return;
    _recovering = true;
    try {
      await _openFuture;
      final id = conversationId;
      if (id == null || _disposed) return;
      final persisted = messages
          .where((message) => !message.id.startsWith('local-'))
          .toList();
      final anchor = persisted.isEmpty ? null : persisted.last.id;
      if (await _loadHistory(recoverToId: anchor)) {
        unawaited(_markConversationRead(id));
      }
      if (_disposed) return;
      for (final message
          in messages
              .where(
                (message) =>
                    message.fromMe &&
                    message.pending &&
                    message.type != 'image',
              )
              .toList()) {
        _sendTypedMessage(message);
      }
    } catch (exception) {
      if (!_disposed) {
        connectionError = exception.toString();
        _notify();
      }
    } finally {
      _recovering = false;
    }
  }

  bool sendText(String rawText) {
    final id = conversationId;
    final text = rawText.trim();
    if (id == null || text.isEmpty) return false;
    final clientMessageId = _newClientMessageId();
    final localMessage = ChatMessage(
      id: 'local-$clientMessageId',
      clientMessageId: clientMessageId,
      text: text,
      sentAt: DateTime.now(),
      fromMe: true,
      pending: true,
    );
    _merge(localMessage);
    _notify();
    try {
      socket.sendText(
        conversationId: id,
        clientMessageId: clientMessageId,
        text: text,
      );
      _startSendTimeout(clientMessageId);
    } catch (exception) {
      _markFailed(clientMessageId);
      error = exception.toString();
      _notify();
    }
    return true;
  }

  Future<void> sendImage(XFile image, {String caption = ''}) async {
    if (conversationId == null) return;
    final clientMessageId = _newClientMessageId();
    final message = ChatMessage(
      id: 'local-$clientMessageId',
      clientMessageId: clientMessageId,
      text: caption.trim(),
      sentAt: DateTime.now(),
      fromMe: true,
      type: 'image',
      mediaLocalPath: image.path,
      pending: true,
    );
    _merge(message);
    _notify();
    await _uploadAndSendImage(message, image);
  }

  void sendLocation(double latitude, double longitude) {
    if (conversationId == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return;
    }
    final clientMessageId = _newClientMessageId();
    final message = ChatMessage(
      id: 'local-$clientMessageId',
      clientMessageId: clientMessageId,
      text: 'Shared a location',
      sentAt: DateTime.now(),
      fromMe: true,
      type: 'location',
      latitude: latitude,
      longitude: longitude,
      pending: true,
    );
    _merge(message);
    _notify();
    _sendTypedMessage(message);
  }

  void retryMessage(ChatMessage message) {
    final id = conversationId;
    final clientId = message.clientMessageId;
    if (id == null || clientId == null || !message.fromMe) return;
    final index = messages.indexWhere(
      (item) => item.clientMessageId == clientId,
    );
    if (index == -1) return;
    messages[index] = message.copyWith(pending: true, failed: false);
    error = null;
    _notify();
    if (message.type == 'image') {
      final path = message.mediaLocalPath;
      if (path == null) {
        _markFailed(clientId);
        error = 'This photo is no longer available. Please select it again.';
        _notify();
      } else {
        unawaited(_uploadAndSendImage(message, XFile(path)));
      }
      return;
    }
    _sendTypedMessage(message);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_messageSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    unawaited(_sentSubscription?.cancel());
    unawaited(_readReceiptSubscription?.cancel());
    unawaited(_reconnectSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    for (final timer in _sendTimeouts.values) {
      timer.cancel();
    }
    _sendTimeouts.clear();
    unawaited(socket.dispose());
    api.close();
    super.dispose();
  }
}
