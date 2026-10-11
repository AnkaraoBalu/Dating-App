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
  });

  final String? id;
  final String? clientMessageId;
  final String sender;
  final String avatar;
  final String text;
  final String time;
  final bool isMe;
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
