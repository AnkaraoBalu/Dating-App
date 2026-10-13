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
    _savedSubscription = socket.savedMessages.listen(_applySaved);
    _expiredSubscription = socket.expiredMessages.listen((event) {
      if (_disposed || event['conversationId'] != conversationId) return;
      final ids = (event['messageIds'] as List?)?.cast<String>() ?? <String>[];
      _applyExpired(ids);
      _notify();
    });
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
  final Set<String> _expiredIds = {};
  StreamSubscription<Map<String, dynamic>>? _savedSubscription;
  final Map<String, Future<void>> _saving = {};
  StreamSubscription<Map<String, dynamic>>? _expiredSubscription;
  final Map<String, Timer> _sendTimeouts = {};
  final StreamController<String> _sendErrors =
      StreamController<String>.broadcast();
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
  Future<Map<String, dynamic>>? _readUpdate;
  bool _readRequested = false;
  Map<String, dynamic>? _latestPeerReceipt;
  bool _disposed = false;
  bool active = true;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Why a message failed to send (for example the send rate limit), so the
  /// screen can explain it next to the "Tap to retry" state.
  Stream<String> get sendErrors => _sendErrors.stream;

  void _reportSendError(Object reason) {
    error = '$reason'.replaceFirst('Exception: ', '');
    if (!_sendErrors.isClosed) _sendErrors.add(error!);
    _notify();
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
        _applyExpired(page.expiredIds);
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
      _applyExpired(page.expiredIds);
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

  Future<void> sendVoice(String path, Duration duration) async {
    if (conversationId == null) return;
    final clientMessageId = _newClientMessageId();
    final message = ChatMessage(
      id: 'local-$clientMessageId',
      clientMessageId: clientMessageId,
      text: '',
      sentAt: DateTime.now(),
      fromMe: true,
      type: 'voice',
      mediaLocalPath: path,
      durationMs: duration.inMilliseconds,
      pending: true,
    );
    _merge(message);
    _notify();
    await _uploadAndSendVoice(message);
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
    if (message.type == 'voice') {
      unawaited(_uploadAndSendVoice(message));
      return;
    }
    _sendTypedMessage(message);
  }

  void _applySaved(Map<String, dynamic> event) {
    if (_disposed || event['conversationId'] != conversationId) return;
    final index = messages.indexWhere(
      (message) => message.id == event['messageId'],
    );
    if (index < 0) return;
    messages[index] = messages[index].copyWith(
      savedInChat: event['savedInChat'] == true,
    );
    _notify();
  }

  Future<void> toggleSaved(ChatMessage message) {
    final id = conversationId;
    if (id == null ||
        message.pending ||
        message.failed ||
        message.id.startsWith('local-')) {
      return Future<void>.value();
    }
    return _saving[message.id] ??= _saveMessage(id, message);
  }

  Future<void> _saveMessage(String id, ChatMessage message) async {
    try {
      _applySaved(
        await api.setSavedInChat(id, message.id, !message.savedInChat),
      );
    } finally {
      _saving.remove(message.id);
    }
  }

  void _applyExpired(List<String> ids) {
    _expiredIds.addAll(ids);
    messages.removeWhere((message) => _expiredIds.contains(message.id));
  }

  /// Expires only received messages loaded in this chat, never unseen history.
  Future<void> leaveConversation() async {
    final id = conversationId;
    if (id == null) return;
    final ids = messages
        .where((message) => !message.fromMe && !message.id.startsWith('local-'))
        .map((message) => message.id)
        .toList();
    try {
      await Future.wait(_saving.values.toList());
      await _readUpdate;
      for (var offset = 0; offset < ids.length; offset += 1000) {
        final expired = await api.expireViewedMessages(
          id,
          ids.sublist(offset, min(offset + 1000, ids.length)),
        );
        _expiredIds.addAll(expired);
      }
      messages.removeWhere((message) => _expiredIds.contains(message.id));
      _notify();
    } catch (error) {
      debugPrint('[Chat] Could not expire viewed messages: $error');
    }
  }

  @override
  void dispose() {
    active = false;
    final leaving = leaveConversation();
    _disposed = true;
    unawaited(_expiredSubscription?.cancel());
    unawaited(_savedSubscription?.cancel());
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
    unawaited(_sendErrors.close());
    unawaited(socket.dispose());
    unawaited(leaving.whenComplete(api.close));
    super.dispose();
  }
}
