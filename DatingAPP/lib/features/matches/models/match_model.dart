import '../../home/data/home_discover_data.dart';

class MatchRecord {
  const MatchRecord({
    required this.id,
    required this.person,
    this.isNew = false,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastActivity = '',
    this.conversationId,
    this.lastActivityAt,
  });

  final String id;
  final HomePerson person;
  final bool isNew;
  final int unreadCount;
  final String? lastMessage;
  final String lastActivity;
  final String? conversationId;
  final DateTime? lastActivityAt;

  bool get hasConversation => conversationId != null || lastMessage != null;

  factory MatchRecord.fromIncomingLike(Map<String, dynamic> json) {
    final record = MatchRecord.fromJson({
      ...json,
      'isNew': true,
      'lastActivity': 'Liked you',
    });
    return record;
  }

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    final profile = Map<String, dynamic>.from(
      json['profile'] as Map? ?? json['person'] as Map? ?? const {},
    );
    final photos = (profile['photos'] as List<dynamic>? ?? [])
        .map(
          (photo) => photo is Map
              ? (photo['secureUrl'] ?? photo['url'])?.toString()
              : photo?.toString(),
        )
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .toList();
    final primaryImage = profile['image']?.toString() ?? '';
    final image = primaryImage.trim().isNotEmpty
        ? primaryImage
        : (photos.isEmpty ? '' : photos.first);
    final interests = (profile['interests'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final person = HomePerson(
      id: profile['id']?.toString() ?? profile['userId']?.toString() ?? '',
      name:
          profile['name']?.toString() ??
          profile['username']?.toString() ??
          'Match',
      age: (profile['age'] as num?)?.toInt() ?? 18,
      image: image,
      photos: photos,
      distance: profile['distance']?.toString() ?? 'Nearby',
      match: (profile['compatibility'] as num?)?.toInt() ?? 0,
      bio: profile['bio']?.toString() ?? '',
      tags: interests,
      verified: profile['verified'] == true,
      online: profile['online'] == true,
    );
    final isNew = json['isNew'] == true || json['status'] == 'new';
    final activityAt = DateTime.tryParse(
      json['lastActivityAt']?.toString() ?? '',
    )?.toLocal();
    return MatchRecord(
      id: json['id']?.toString() ?? person.id,
      person: person,
      isNew: isNew,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessage: json['lastMessage']?.toString(),
      lastActivity: activityAt == null
          ? (json['lastActivity']?.toString() ?? (isNew ? 'New' : ''))
          : _relativeActivity(activityAt, DateTime.now()),
      conversationId: json['conversationId']?.toString(),
      lastActivityAt: activityAt,
    );
  }
}

String _relativeActivity(DateTime activity, DateTime now) {
  final elapsed = now.difference(activity);
  if (elapsed.inSeconds < 60) return 'now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d';
  return '${activity.month}/${activity.day}';
}

abstract final class MatchDemoData {
  static const matches = <MatchRecord>[
    MatchRecord(
      id: 'demo-maya',
      person: HomePerson(
        id: 'demo-maya',
        name: 'Maya',
        age: 23,
        image: 'assets/images/girls-images/golden_hour_portrait.png',
        distance: '2 km away',
        match: 92,
        bio: 'Good coffee, deep conversations and spontaneous trips ✨',
        tags: ['Coffee', 'Travel', 'Music'],
        online: true,
        verified: true,
      ),
      unreadCount: 2,
      lastMessage: 'Hey! How was your day? ✨',
      lastActivity: '2m',
    ),
    MatchRecord(
      id: 'demo-aarav',
      person: HomePerson(
        id: 'demo-aarav',
        name: 'Aarav',
        age: 24,
        image: 'assets/images/boys-images/cafe_smiling_portrait.png',
        distance: '5 km away',
        match: 88,
        bio: 'Always up for a new cafe and a good playlist.',
        tags: ['Coffee', 'Music'],
        online: true,
      ),
      isNew: true,
      lastMessage: 'Liked your story ❤️',
      lastActivity: '12m',
    ),
    MatchRecord(
      id: 'demo-kiara',
      person: HomePerson(
        id: 'demo-kiara',
        name: 'Kiara',
        age: 22,
        image: 'assets/images/girls-images/cafe_coffee_portrait.png',
        distance: '8 km away',
        match: 85,
        bio: 'That place looks amazing! Let’s go sometime.',
        tags: ['Food', 'Travel'],
      ),
      unreadCount: 1,
      lastMessage: 'That place looks amazing!',
      lastActivity: '1h',
    ),
    MatchRecord(
      id: 'demo-rohan',
      person: HomePerson(
        id: 'demo-rohan',
        name: 'Rohan',
        age: 25,
        image: 'assets/images/boys-images/rooftop_sunset_portrait.png',
        distance: '3 km away',
        match: 81,
        bio: 'Let’s plan this weekend? 🌇',
        tags: ['Travel', 'Food'],
      ),
      lastMessage: 'Let’s plan this weekend?',
      lastActivity: '3h',
    ),
  ];
}
