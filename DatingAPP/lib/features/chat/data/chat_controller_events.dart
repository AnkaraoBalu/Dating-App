part of 'chat_controller.dart';

// Applies socket events (messages, confirmations, read receipts, errors) to the local message list.
extension _ChatControllerEvents on ChatController {
  void _receiveMessage(Map<String, dynamic> json) {
    if (json['conversationId'] != conversationId) return;
    if (_disposed) return;
    final message = ChatMessage.fromJson(
      json,
      peerUserId: _peerUserId ?? '',
      currentUserId: socket.currentUserId,
    );
    _merge(message);
    _notify();
    if (!message.fromMe) {
      final id = conversationId;
      if (id != null) unawaited(_markConversationRead(id));
    }
  }

  Future<void> _markConversationRead(String id) async {
    if (_disposed || !active) return;
    _readRequested = true;
    if (_reading) return;
    _reading = true;
    try {
      while (_readRequested && !_disposed && active && conversationId == id) {
        _readRequested = false;
        _readUpdate = api.markConversationRead(id);
        await _readUpdate;
      }
    } catch (_) {
      // Reopening or reconnecting retries the read update.
    } finally {
      _reading = false;
    }
  }

  void _receiveReadReceipt(Map<String, dynamic> json) {
    if (_disposed || json['conversationId'] != conversationId) return;
    final readerId = json['readerId']?.toString();
    if (readerId != null && readerId != _peerUserId) return;
    _latestPeerReceipt = json;
    final lastReadMessageId = json['lastReadMessageId']?.toString();
    final readAt = DateTime.tryParse(
      json['readAt']?.toString() ?? '',
    )?.toLocal();
    if (lastReadMessageId == null || readAt == null) return;
    final lastReadIndex = messages.indexWhere(
      (message) => message.id == lastReadMessageId,
    );
    if (lastReadIndex < 0) return;
    for (var index = 0; index <= lastReadIndex; index++) {
      final message = messages[index];
      if (message.fromMe && !message.pending) {
        messages[index] = message.copyWith(readAt: readAt);
      }
    }
    _notify();
  }

  void _receiveError(Map<String, dynamic> json) {
    final clientMessageId = json['clientMessageId']?.toString();
    if (clientMessageId == null) return;
    _sendTimeouts.remove(clientMessageId)?.cancel();
    _markFailed(clientMessageId);
    _reportSendError(json['message'] ?? 'Message could not be sent.');
  }

  void _confirmMessage(Map<String, dynamic> json) {
    if (_disposed) return;
    final savedMessage = json['message'];
    if (savedMessage is Map) {
      _receiveMessage(Map<String, dynamic>.from(savedMessage));
    }
    final clientMessageId = json['clientMessageId']?.toString();
    if (clientMessageId == null) return;
    _sendTimeouts.remove(clientMessageId)?.cancel();
    final index = messages.indexWhere(
      (message) => message.clientMessageId == clientMessageId,
    );
    if (index == -1) return;
    messages[index] = messages[index].copyWith(
      id: json['messageId']?.toString(),
      pending: false,
      failed: false,
    );
    _notify();
  }

  void _startSendTimeout(String clientMessageId) {
    _sendTimeouts.remove(clientMessageId)?.cancel();
    _sendTimeouts[clientMessageId] = Timer(const Duration(seconds: 20), () {
      _markFailed(clientMessageId);
      _notify();
    });
  }

  void _markFailed(String clientMessageId) {
    final index = messages.indexWhere(
      (message) => message.clientMessageId == clientMessageId,
    );
    if (index != -1) {
      messages[index] = messages[index].copyWith(pending: false, failed: true);
    }
  }

  void _merge(ChatMessage incoming) {
    if (incoming.type == 'expired' || _expiredIds.contains(incoming.id)) {
      _expiredIds.add(incoming.id);
      messages.removeWhere(
        (message) =>
            message.id == incoming.id ||
            (incoming.fromMe &&
                message.clientMessageId == incoming.clientMessageId),
      );
      return;
    }
    final index = messages.indexWhere(
      (message) =>
          (incoming.id.isNotEmpty && message.id == incoming.id) ||
          (incoming.clientMessageId != null &&
              message.clientMessageId == incoming.clientMessageId &&
              (incoming.senderId != null && message.senderId != null
                  ? incoming.senderId == message.senderId
                  : incoming.fromMe == message.fromMe)),
    );
    if (index == -1) {
      messages.add(incoming);
    } else {
      if (!incoming.pending) {
        final clientId = messages[index].clientMessageId;
        if (clientId != null) _sendTimeouts.remove(clientId)?.cancel();
      }
      final previous = messages[index];
      final readAt =
          previous.readAt != null &&
              (incoming.readAt == null ||
                  previous.readAt!.isAfter(incoming.readAt!))
          ? previous.readAt
          : incoming.readAt;
      messages[index] = incoming.copyWith(
        readAt: readAt,
        mediaLocalPath: incoming.mediaUrl == null
            ? previous.mediaLocalPath
            : null,
        clearMediaLocalPath: incoming.mediaUrl != null,
      );
    }
    messages.sort((a, b) {
      final timeOrder = a.sentAt.compareTo(b.sentAt);
      return timeOrder != 0 ? timeOrder : a.id.compareTo(b.id);
    });
    final receipt = _latestPeerReceipt;
    if (receipt != null) _receiveReadReceipt(receipt);
  }
}
