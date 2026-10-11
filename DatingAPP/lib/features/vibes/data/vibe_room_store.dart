import 'package:flutter/foundation.dart';

import '../models/vibe_room.dart';

abstract final class VibeRoomSeeds {
  static const aanya = VibeRoomMember(
    id: 'aanya',
    name: 'Aanya',
    age: 22,
    avatar: 'assets/images/girls-images/golden_hour_portrait.png',
    bio: 'Coffee, long conversations and spontaneous plans.',
    tags: ['Coffee', 'Travel', 'Music'],
    role: 'Host',
  );
  static const meera = VibeRoomMember(
    id: 'meera',
    name: 'Meera',
    age: 23,
    avatar: 'assets/images/girls-images/cafe_coffee_portrait.png',
    bio: 'Finding the best cafés and playlists in town.',
    tags: ['Coffee', 'Books', 'Music'],
    role: 'Speaker',
  );
  static const rohan = VibeRoomMember(
    id: 'rohan',
    name: 'Rohan',
    age: 24,
    avatar: 'assets/images/boys-images/rooftop_sunset_portrait.png',
    bio: 'Weekend traveler and amateur guitarist.',
    tags: ['Travel', 'Music', 'Food'],
    role: 'Speaker',
  );
  static const diya = VibeRoomMember(
    id: 'diya',
    name: 'Diya',
    age: 23,
    avatar: 'assets/images/girls-images/sunset_floral_portrait.png',
    bio: 'Sunsets, good stories and new friends.',
    tags: ['Travel', 'Art', 'Coffee'],
  );
  static const kabir = VibeRoomMember(
    id: 'kabir',
    name: 'Kabir',
    age: 25,
    avatar: 'assets/images/boys-images/cafe_smiling_portrait.png',
    bio: 'Always up for a friendly game or a late chat.',
    tags: ['Gaming', 'Movies', 'Food'],
  );
  static const me = VibeRoomMember(
    id: 'you',
    name: 'You',
    age: 24,
    avatar: 'assets/images/boys-images/golden_hour_white_shirt.png',
    bio: 'Here to meet kind, interesting people.',
    tags: ['Coffee', 'Travel', 'Music'],
    role: 'Host',
  );

  static final rooms = <VibeRoom>[
    VibeRoom(
      id: 'late-night-talks',
      title: 'Late Night Talks',
      description:
          'Real conversations, good people, and a little bit of magic.',
      categoryId: 'late_night_talks',
      emoji: '🌙',
      coverAsset: 'assets/images/girls-images/city_night_portrait.png',
      hostName: 'Aanya',
      hostAvatar: aanya.avatar,
      participantCount: 124,
      tags: ['Deep Talks', 'Friends', 'Open mic'],
      members: [aanya, rohan, diya, kabir],
      messages: [
        VibeRoomMessage(
          sender: 'Rohan',
          avatar: rohan.avatar,
          text: 'Mine is Third Wave! Amazing vibe ☕',
          time: '9:41 PM',
        ),
        VibeRoomMessage(
          sender: 'Diya',
          avatar: diya.avatar,
          text: 'Same! I love their hazelnut latte.',
          time: '9:42 PM',
        ),
        VibeRoomMessage(
          sender: 'Kabir',
          avatar: kabir.avatar,
          text: 'Any good night cafes around here?',
          time: '9:42 PM',
        ),
      ],
    ),
    VibeRoom(
      id: 'coffee-conversations',
      title: 'Coffee & Conversations',
      description:
          'Meet new people who love good coffee and easy conversation.',
      categoryId: 'coffee_chats',
      emoji: '☕',
      coverAsset: 'assets/images/girls-images/cafe_coffee_portrait.png',
      hostName: 'Meera',
      hostAvatar: meera.avatar,
      participantCount: 124,
      tags: ['Coffee', 'Travel', 'Music', 'Art'],
      members: [meera, aanya, rohan, diya, kabir],
      messages: [
        VibeRoomMessage(
          sender: 'Aanya',
          avatar: aanya.avatar,
          text: 'What’s your favourite café in Hyderabad?',
          time: '9:41 PM',
        ),
        VibeRoomMessage(
          sender: 'Rohan',
          avatar: rohan.avatar,
          text: 'Mine is Third Wave! Amazing vibe ☕',
          time: '9:42 PM',
        ),
        VibeRoomMessage(
          sender: 'Diya',
          avatar: diya.avatar,
          text: 'Same! I love their hazelnut latte.',
          time: '9:43 PM',
        ),
      ],
    ),
    VibeRoom(
      id: 'music-vibes',
      title: 'Music Vibes',
      description: 'Swap playlists, talk live gigs and find your next song.',
      categoryId: 'music_chill',
      emoji: '🎧',
      coverAsset: 'assets/images/boys-images/acoustic_guitar_portrait.png',
      hostName: 'Kabir',
      hostAvatar: kabir.avatar,
      participantCount: 87,
      tags: ['Music', 'Live gigs', 'Playlists'],
      members: [kabir, meera, aanya, rohan],
      messages: [
        VibeRoomMessage(
          sender: 'Meera',
          avatar: meera.avatar,
          text: 'What’s on repeat for everyone today?',
          time: '8:08 PM',
        ),
        VibeRoomMessage(
          sender: 'Kabir',
          avatar: kabir.avatar,
          text: 'A little indie and a lot of old Bollywood.',
          time: '8:09 PM',
        ),
      ],
    ),
    VibeRoom(
      id: 'travel-souls',
      title: 'Travel Souls',
      description: 'Find your next destination and someone to explore it with.',
      categoryId: 'travel_buddies',
      emoji: '✈️',
      coverAsset: 'assets/images/boys-images/rooftop_sunset_portrait.png',
      hostName: 'Rohan',
      hostAvatar: rohan.avatar,
      participantCount: 64,
      tags: ['Travel', 'Weekend plans', 'Friends'],
      isLive: false,
      scheduledFor: 'Tomorrow · 8:00 PM',
      members: [rohan, diya, meera],
      messages: const [],
    ),
    VibeRoom(
      id: 'movie-buffs',
      title: 'Movie Buffs',
      description: 'Spoiler-free movie chat and cozy watch party plans.',
      categoryId: 'gaming_together',
      emoji: '🍿',
      coverAsset: 'assets/images/girls-images/cozy_headphones_portrait.png',
      hostName: 'Diya',
      hostAvatar: diya.avatar,
      participantCount: 42,
      tags: ['Movies', 'Pop culture', 'Friends'],
      members: [diya, kabir, aanya],
      messages: const [],
    ),
    VibeRoom(
      id: 'hyderabad-foodies',
      title: 'Hyderabad Foodies',
      description: 'Share your favourite bites and plan the next food walk.',
      categoryId: 'food_adventures',
      emoji: '🍜',
      coverAsset: 'assets/images/girls-images/iced_coffee_portrait.png',
      hostName: 'You',
      hostAvatar: me.avatar,
      participantCount: 24,
      tags: ['Food', 'Hyderabad', 'Weekend plans'],
      isHostedByMe: true,
      members: [me, aanya, rohan, meera],
      messages: const [],
    ),
  ];
}

class VibeRoomStore extends ChangeNotifier {
  VibeRoomStore._();

  static final VibeRoomStore instance = VibeRoomStore._();

  final List<VibeRoom> rooms = [...VibeRoomSeeds.rooms];
  final Set<String> joinedIds = {'late-night-talks', 'music-vibes'};
  final Set<String> savedIds = {'travel-souls'};
  final Set<String> historyIds = {};
  final Set<String> followingMemberIds = {};

  VibeRoom? byId(String id) => rooms.where((room) => room.id == id).firstOrNull;

  List<VibeRoom> get hosted =>
      rooms.where((room) => room.isHostedByMe).toList();
  List<VibeRoom> get joined =>
      rooms.where((room) => joinedIds.contains(room.id)).toList();
  List<VibeRoom> get saved =>
      rooms.where((room) => savedIds.contains(room.id)).toList();
  List<VibeRoom> get history =>
      rooms.where((room) => historyIds.contains(room.id)).toList();

  void replaceRooms(List<VibeRoom> updatedRooms) {
    rooms
      ..clear()
      ..addAll(updatedRooms);
    joinedIds
      ..clear()
      ..addAll(
        updatedRooms.where((room) => room.isJoined).map((room) => room.id),
      );
    savedIds
      ..clear()
      ..addAll(
        updatedRooms.where((room) => room.isSaved).map((room) => room.id),
      );
    notifyListeners();
  }

  void cacheRoom(VibeRoom room) {
    final index = rooms.indexWhere((item) => item.id == room.id);
    if (index == -1) {
      rooms.insert(0, room);
    } else {
      rooms[index] = room;
    }
    if (room.isSaved) {
      savedIds.add(room.id);
    } else {
      savedIds.remove(room.id);
    }
    if (room.isJoined) {
      joinedIds.add(room.id);
    } else {
      joinedIds.remove(room.id);
    }
    notifyListeners();
  }

  void toggleSaved(VibeRoom room) {
    if (!savedIds.add(room.id)) savedIds.remove(room.id);
    notifyListeners();
  }

  void join(VibeRoom room) {
    room.isJoined = true;
    if (joinedIds.add(room.id)) room.participantCount++;
    notifyListeners();
  }

  void leave(VibeRoom room) {
    room.isJoined = false;
    if (joinedIds.remove(room.id) && room.participantCount > 0) {
      room.participantCount--;
    }
    historyIds.add(room.id);
    notifyListeners();
  }

  void goLive(VibeRoom room) {
    room.isLive = true;
    room.scheduledFor = null;
    if (joinedIds.add(room.id)) room.participantCount++;
    notifyListeners();
  }

  void toggleFollow(String memberId) {
    if (!followingMemberIds.add(memberId)) {
      followingMemberIds.remove(memberId);
    }
    notifyListeners();
  }

  VibeRoom create({
    required String title,
    required String description,
    required String categoryId,
    required String emoji,
    required String coverAsset,
    required int maxParticipants,
    required bool inviteOnly,
    List<String> tags = const [],
  }) {
    final room = VibeRoom(
      id: 'room-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      categoryId: categoryId,
      emoji: emoji,
      coverAsset: coverAsset,
      hostName: 'You',
      hostAvatar: VibeRoomSeeds.me.avatar,
      participantCount: 1,
      maxParticipants: maxParticipants,
      inviteOnly: inviteOnly,
      isLive: false,
      isHostedByMe: true,
      isJoined: true,
      tags: tags.isEmpty ? [emoji, title] : tags,
      members: const [VibeRoomSeeds.me],
      messages: const [],
    );
    rooms.insert(0, room);
    notifyListeners();
    return room;
  }

  void updateRoom(
    VibeRoom room, {
    String? title,
    String? description,
    bool? inviteOnly,
    int? maxParticipants,
    List<String>? guidelines,
    String? categoryId,
    String? emoji,
  }) {
    if (title != null) room.title = title;
    if (description != null) room.description = description;
    if (inviteOnly != null) room.inviteOnly = inviteOnly;
    if (maxParticipants != null) room.maxParticipants = maxParticipants;
    if (guidelines != null) room.guidelines = guidelines;
    if (categoryId != null) room.categoryId = categoryId;
    if (emoji != null) room.emoji = emoji;
    notifyListeners();
  }

  void delete(VibeRoom room) {
    rooms.removeWhere((item) => item.id == room.id);
    joinedIds.remove(room.id);
    savedIds.remove(room.id);
    historyIds.remove(room.id);
    notifyListeners();
  }
}
