import 'package:flutter/foundation.dart';

import '../models/vibe_room.dart';

/// Stands in for the member on rooms created without a backend (tests).
const _localHost = VibeRoomMember(
  id: 'you',
  name: 'You',
  age: 0,
  avatar: 'assets/images/boys-images/golden_hour_white_shirt.png',
  bio: '',
  tags: [],
  role: 'Host',
);

class VibeRoomStore extends ChangeNotifier {
  VibeRoomStore._();

  static final VibeRoomStore instance = VibeRoomStore._();

  // Filled from the backend; empty until the first load succeeds.
  final List<VibeRoom> rooms = [];
  final Set<String> joinedIds = {};
  final Set<String> savedIds = {};
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
      hostAvatar: _localHost.avatar,
      participantCount: 1,
      maxParticipants: maxParticipants,
      inviteOnly: inviteOnly,
      isLive: false,
      isHostedByMe: true,
      isJoined: true,
      tags: tags.isEmpty ? [emoji, title] : tags,
      members: const [_localHost],
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
