/// The kinds of push notification the API sends (see the backend's
/// `notifications.service.ts`). The type decides which screen a tap opens.
enum PushNotificationType { message, match, like, unknown }

class PushNotification {
  const PushNotification({
    required this.type,
    this.title = '',
    this.body = '',
    this.conversationId,
    this.userId,
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
      _ => PushNotificationType.unknown,
    };
    return PushNotification(
      type: type,
      title: title ?? '',
      body: body ?? '',
      conversationId: data['conversationId']?.toString(),
      userId: data['userId']?.toString(),
    );
  }

  final PushNotificationType type;
  final String title;
  final String body;

  /// For [PushNotificationType.message]: the conversation to open.
  final String? conversationId;

  /// For [PushNotificationType.match]: the member you matched with.
  final String? userId;
}
