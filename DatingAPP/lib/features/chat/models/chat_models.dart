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

abstract final class ChatDemoData {
  static List<ChatMessage> messagesFor(MatchRecord match) {
    final now = DateTime.now();
    if (match.person.name == 'Maya') {
      return [
        ChatMessage(
          id: 'maya-1',
          text: 'Hey! How was your day? ✨',
          sentAt: now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'maya-2',
          text: 'It was good! Just had an amazing coffee ☕',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 48)),
          fromMe: true,
        ),
        ChatMessage(
          id: 'maya-3',
          text: 'Nice! Which place?',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 42)),
        ),
        ChatMessage(
          id: 'maya-4',
          text: 'This one! The view was insane 🌅',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 35)),
          fromMe: true,
          mediaUrl: 'assets/images/girls-images/cafe_coffee_portrait.png',
          mediaType: 'photo',
        ),
        ChatMessage(
          id: 'maya-5',
          text: 'Woah 😍 Let’s go there together sometime?',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        ),
        ChatMessage(
          id: 'maya-6',
          text: 'I’d love that! This weekend? 💕',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 12)),
          fromMe: true,
        ),
      ];
    }
    return [
      ChatMessage(
        id: '${match.id}-1',
        text: match.lastMessage ?? 'Hey! Glad we matched 😊',
        sentAt: now.subtract(const Duration(minutes: 22)),
      ),
      ChatMessage(
        id: '${match.id}-2',
        text: 'That sounds amazing! Tell me more ✨',
        sentAt: now.subtract(const Duration(minutes: 16)),
        fromMe: true,
      ),
    ];
  }

  static const media = [
    'assets/images/girls-images/golden_hour_portrait.png',
    'assets/images/girls-images/cafe_coffee_portrait.png',
    'assets/images/girls-images/sunset_floral_portrait.png',
    'assets/images/girls-images/iced_coffee_portrait.png',
    'assets/images/girls-images/cozy_headphones_portrait.png',
    'assets/images/girls-images/city_night_portrait.png',
  ];
}

HomePerson chatPerson(MatchRecord match) => match.person;
