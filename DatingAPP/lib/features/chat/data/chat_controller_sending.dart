part of 'chat_controller.dart';

// Client message IDs, image upload and socket send for outgoing messages.
extension _ChatControllerSending on ChatController {
  String _newClientMessageId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  Future<void> _uploadAndSendImage(ChatMessage message, XFile image) async {
    final clientId = message.clientMessageId;
    final conversation = conversationId;
    final peerId = _peerUserId;
    if (clientId == null || conversation == null || peerId == null) return;
    try {
      final savedMessage = await api.sendImage(
        conversationId: conversation,
        image: image,
        clientMessageId: clientId,
        peerUserId: peerId,
        caption: message.text,
      );
      if (_disposed || conversation != conversationId) return;
      _merge(savedMessage.copyWith(clearMediaLocalPath: true));
      _sendTimeouts.remove(clientId)?.cancel();
      _notify();
    } catch (exception) {
      _markFailed(clientId);
      error = exception.toString();
      _notify();
    }
  }

  void _sendTypedMessage(ChatMessage message) {
    final conversation = conversationId;
    final clientId = message.clientMessageId;
    if (conversation == null || clientId == null) return;
    try {
      socket.sendMessage({
        'conversationId': conversation,
        'clientMessageId': clientId,
        'type': message.type,
        'text': message.text,
        if (message.type == 'location') ...{
          'latitude': message.latitude,
          'longitude': message.longitude,
        },
      });
      _startSendTimeout(clientId);
    } catch (exception) {
      _markFailed(clientId);
      error = exception.toString();
      _notify();
    }
  }
}
