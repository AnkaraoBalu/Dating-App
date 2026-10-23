import '../../home/data/home_discover_data.dart';
import '../../matches/models/match_model.dart';

class ChatMessage {
  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String peerUserId,
    String? currentUserId,
  }) {
    final senderId = json['senderId']?.toString();
    final fromMe = senderId != null && currentUserId != null
        ? senderId == currentUserId
        : json['fromMe'] is bool
        ? json['fromMe'] as bool
        : senderId != null && senderId != peerUserId;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: senderId,
      clientMessageId: json['clientMessageId']?.toString(),
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      savedInChat: json['savedInChat'] == true,
      mediaUrl: json['mediaUrl']?.toString(),
      mediaType: json['mediaMimeType']?.toString(),
      durationMs: (json['mediaDurationMs'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? '')?.toLocal(),
      sentAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      fromMe: fromMe,
    );
  }

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    this.type = 'text',
    this.fromMe = false,
    this.mediaUrl,
    this.mediaLocalPath,
    this.mediaType,
    this.durationMs,
    this.latitude,
    this.longitude,
    this.clientMessageId,
    this.savedInChat = false,
    this.pending = false,
    this.failed = false,
    this.readAt,
    this.senderId,
  });

  final String id;
  final String? senderId;
  final String text;
  final DateTime sentAt;
  final bool fromMe;
  final String type;
  final String? mediaUrl;
  final String? mediaLocalPath;
  final String? mediaType;

  /// Length of a voice message's clip.
  final int? durationMs;
  final double? latitude;
  final double? longitude;
  final String? clientMessageId;
  final bool savedInChat;
  final bool pending;
  final bool failed;
  final DateTime? readAt;

  ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? sentAt,
    bool? fromMe,
    String? type,
    String? mediaUrl,
    String? mediaLocalPath,
    String? clientMessageId,
    double? latitude,
    double? longitude,
    bool? savedInChat,
    bool? pending,
    bool? failed,
    DateTime? readAt,
    bool clearMediaLocalPath = false,
  }) => ChatMessage(
    id: id ?? this.id,
    senderId: senderId,
    text: text ?? this.text,
    sentAt: sentAt ?? this.sentAt,
    fromMe: fromMe ?? this.fromMe,
    type: type ?? this.type,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaLocalPath: clearMediaLocalPath
        ? null
        : mediaLocalPath ?? this.mediaLocalPath,
    mediaType: mediaType,
    durationMs: durationMs,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    clientMessageId: clientMessageId ?? this.clientMessageId,
    savedInChat: savedInChat ?? this.savedInChat,
    pending: pending ?? this.pending,
    failed: failed ?? this.failed,
    readAt: readAt ?? this.readAt,
  );
}

class ChatMessagePage {
  const ChatMessagePage({
    required this.items,
    required this.hasMore,
    this.expiredIds = const [],
    this.nextCursor,
  });

  final List<ChatMessage> items;
  final bool hasMore;
  final List<String> expiredIds;
  final String? nextCursor;
}

HomePerson chatPerson(MatchRecord match) => match.person;
