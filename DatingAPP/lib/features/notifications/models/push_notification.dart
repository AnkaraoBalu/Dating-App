/// The kinds of push notification the API sends (see the backend's
/// `notifications.service.ts`). The type decides which screen a tap opens.
enum PushNotificationType { message, match, like, vibe, call, unknown }

class PushNotification {
  const PushNotification({
    required this.type,
    this.title = '',
    this.body = '',
    this.conversationId,
    this.userId,
    this.roomId,
    this.callId,
  });

  /// Reads the `data` payload of a Firebase message.
  factory PushNotification.fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final type = switch (data['type']) {
      'message' => PushNotificationType.message,
      'match' => PushNotificationType.match,
      'like' => PushNotificationType.like,
      'vibe' => PushNotificationType.vibe,
      'call' => PushNotificationType.call,
      _ => PushNotificationType.unknown,
    };
    return PushNotification(
      type: type,
      title: title ?? '',
      body: body ?? '',
      conversationId: data['conversationId']?.toString(),
      userId: data['userId']?.toString(),
      roomId: data['roomId']?.toString(),
      callId: data['callId']?.toString(),
    );
  }

  final PushNotificationType type;
  final String title;
  final String body;

  /// For [PushNotificationType.message]: the conversation to open.
  final String? conversationId;

  /// For [PushNotificationType.match]: the member you matched with.
  final String? userId;

  /// For [PushNotificationType.vibe]: the Vibe room with the new activity.
  final String? roomId;

  /// For [PushNotificationType.call]: the call that is ringing.
  final String? callId;
}
