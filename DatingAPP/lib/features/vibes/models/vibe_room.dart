import '../data/vibe_artwork.dart';

class VibeRoomMember {
  const VibeRoomMember({
    required this.id,
    required this.name,
    required this.age,
    required this.avatar,
    this.bio = '',
    this.tags = const [],
    this.role = 'Listener',
    this.online = true,
  });

  final String id;
  final String name;
  final int age;
  final String avatar;
  final String bio;
  final List<String> tags;
  final String role;
  final bool online;
}

class VibeRoomMessage {
  const VibeRoomMessage({
    required this.sender,
    required this.avatar,
    required this.text,
    required this.time,
    this.id,
    this.clientMessageId,
    this.isMe = false,
    this.kind = 'text',
    this.mediaUrl,
    this.mediaLocalPath,
    this.durationMs,
  });

  final String? id;
  final String? clientMessageId;
  final String sender;
  final String avatar;
  final String text;
  final String time;
  final bool isMe;

  /// "text", "voice", or "join" for the "… joined the room" line.
  final String kind;
  final String? mediaUrl;

  /// The sender's own recording, played before (and after) upload.
  final String? mediaLocalPath;
  final int? durationMs;

  bool get isVoice => kind == 'voice';

  VibeRoomMessage copyWith({String? avatar, String? mediaLocalPath}) =>
      VibeRoomMessage(
        id: id,
        clientMessageId: clientMessageId,
        sender: sender,
        avatar: avatar ?? this.avatar,
        text: text,
        time: time,
        isMe: isMe,
        kind: kind,
        mediaUrl: mediaUrl,
        mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
        durationMs: durationMs,
      );
}

/// A joined Vibe room presented as a group conversation in the Chat tab.
class VibeRoomChat {
  const VibeRoomChat({
    required this.room,
    required this.unreadCount,
    required this.lastActivityAt,
    this.lastMessage,
  });

  final VibeRoom room;
  final int unreadCount;
  final DateTime? lastActivityAt;
  final VibeRoomChatMessage? lastMessage;
}

class VibeRoomChatMessage {
  const VibeRoomChatMessage({
    required this.text,
    required this.sender,
    required this.isMe,
    required this.kind,
  });

  final String text;
  final String sender;
  final bool isMe;
  final String kind;

  String get preview {
    if (kind == 'join') return '$sender joined the room';
    final body = kind == 'voice' ? '🎤 Voice message' : text;
    return isMe ? 'You: $body' : '$sender: $body';
  }
}

class VibeVoiceCredentials {
  const VibeVoiceCredentials({
    required this.serverUrl,
    required this.participantToken,
    required this.identity,
    required this.name,
    required this.avatar,
    required this.role,
  });

  final String serverUrl;
  final String participantToken;
  final String identity;
  final String name;
  final String avatar;
  final String role;

  factory VibeVoiceCredentials.fromJson(Map<String, dynamic> json) {
    final participant = json['participant'];
    if (participant is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice room credentials.');
    }
    return VibeVoiceCredentials(
      serverUrl: json['serverUrl']?.toString() ?? '',
      participantToken: json['participantToken']?.toString() ?? '',
      identity: participant['identity']?.toString() ?? '',
      name: participant['name']?.toString() ?? 'You',
      avatar: participant['avatar']?.toString() ?? '',
      role: participant['role']?.toString() ?? 'Listener',
    );
  }
}

class VibeRoom {
  VibeRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.emoji,
    required this.coverAsset,
    required this.hostName,
    required this.hostAvatar,
    required this.participantCount,
    required this.members,
    required this.messages,
    this.tags = const [],
    this.city = 'Hyderabad',
    this.isLive = true,
    this.isHostedByMe = false,
    this.isJoined = false,
    this.inviteOnly = false,
    this.maxParticipants = 50,
    this.scheduledFor,
    this.isSaved = false,
    this.guidelines = const [
      'Be kind and respectful',
      'No hate speech or spamming',
      'Keep conversations safe',
    ],
  });

  final String id;
  String title;
  String description;
  String categoryId;
  String emoji;
  String coverAsset;
  String get coverImage =>
      VibeArtwork.roomCover(coverAsset, categoryId: categoryId);
  String hostName;
  String hostAvatar;
  int participantCount;
  final List<VibeRoomMember> members;
  final List<VibeRoomMessage> messages;
  List<String> tags;
  String city;
  bool isLive;
  bool isHostedByMe;
  bool isJoined;
  bool inviteOnly;
  int maxParticipants;
  String? scheduledFor;
  bool isSaved;
  List<String> guidelines;
}
