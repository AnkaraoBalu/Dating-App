import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vibe_room.dart';

class VibeRoomsApi {
  VibeRoomsApi({required this.baseUrl, required this.getSessionToken});

  final String baseUrl;
  final Future<String> Function() getSessionToken;

  Future<List<VibeRoom>> listRooms({String? categoryId}) async {
    final query = <String, String>{
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };
    final uri = Uri.parse(
      '$baseUrl/vibe-rooms',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const FormatException('Invalid vibe rooms response.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_roomFromJson)
        .toList();
  }

  Future<VibeRoom> joinRoom(String roomId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/join'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid join room response.');
    }
    return _roomFromJson(decoded);
  }

  Future<VibeRoom> leaveRoom(String roomId) async {
    final response = await http
        .delete(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/membership',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid leave room response.');
    }
    return _roomFromJson(decoded);
  }

  Future<List<VibeRoomMessage>> listMessages(
    String roomId, {
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/messages',
    ).replace(queryParameters: {'limit': '$limit'});
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const FormatException('Invalid vibe room messages response.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(messageFromJson)
        .toList();
  }

  Future<VibeRoomMessage> sendMessage({
    required String roomId,
    required String clientMessageId,
    required String text,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/messages',
          ),
          headers: await _headers(),
          body: jsonEncode({'clientMessageId': clientMessageId, 'text': text}),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid sent vibe room message.');
    }
    return messageFromJson(decoded);
  }

  Future<VibeRoom> createRoom({
    required String title,
    required String description,
    required String categoryId,
    required String emoji,
    required String coverAsset,
    required List<String> tags,
    required int maxParticipants,
    required bool inviteOnly,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/vibe-rooms'),
          headers: await _headers(),
          body: jsonEncode({
            'title': title,
            'description': description,
            'categoryId': categoryId,
            'emoji': emoji,
            'coverAsset': coverAsset,
            'tags': tags,
            'maxParticipants': maxParticipants,
            'inviteOnly': inviteOnly,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid create room response.');
    }
    return _roomFromJson(decoded);
  }

  Future<void> setSaved(String roomId, bool saved) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/saved'),
          headers: await _headers(),
          body: jsonEncode({'saved': saved}),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  Future<Map<String, String>> _headers() async => {
    'Authorization':
        'Bearer ${await getSessionToken().timeout(const Duration(seconds: 10))}',
    'Content-Type': 'application/json',
  };

  Object? _decode(http.Response response) {
    final Object? decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      throw Exception(message ?? 'Request failed (${response.statusCode}).');
    }
    return decoded;
  }

  VibeRoom _roomFromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = rawMembers is List
        ? rawMembers.whereType<Map<String, dynamic>>().map((member) {
            final tags = member['tags'];
            return VibeRoomMember(
              id: member['id'] as String? ?? '',
              name: member['name'] as String? ?? 'Member',
              age: member['age'] is num ? (member['age'] as num).toInt() : 0,
              avatar:
                  member['avatar'] as String? ??
                  'assets/images/boys-images/golden_hour_white_shirt.png',
              bio: member['bio'] as String? ?? '',
              tags: tags is List ? tags.whereType<String>().toList() : const [],
              role: member['role'] as String? ?? 'Listener',
              online: member['online'] as bool? ?? false,
            );
          }).toList()
        : <VibeRoomMember>[];
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages.whereType<Map<String, dynamic>>().map((message) {
            return VibeRoomMessage(
              id: message['id'] as String?,
              clientMessageId: message['clientMessageId'] as String?,
              sender: message['sender'] as String? ?? 'Member',
              avatar: message['avatar'] as String? ?? '',
              text: message['text'] as String? ?? '',
              time: _displayTime(message['time'] as String?),
              isMe: message['isMe'] as bool? ?? false,
            );
          }).toList()
        : <VibeRoomMessage>[];
    final tags = json['tags'];

    return VibeRoom(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Vibe room',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '✨',
      coverAsset:
          json['coverAsset'] as String? ??
          'assets/images/girls-images/cafe_coffee_portrait.png',
      hostName: json['hostName'] as String? ?? 'Member',
      hostAvatar:
          json['hostAvatar'] as String? ??
          'assets/images/boys-images/golden_hour_white_shirt.png',
      participantCount: json['participantCount'] is num
          ? (json['participantCount'] as num).toInt()
          : 0,
      members: members,
      messages: messages,
      tags: tags is List ? tags.whereType<String>().toList() : const [],
      city: json['city'] as String? ?? 'Hyderabad',
      isLive: json['isLive'] as bool? ?? false,
      isHostedByMe: json['isHostedByMe'] as bool? ?? false,
      isJoined: json['isJoined'] as bool? ?? false,
      inviteOnly: json['inviteOnly'] as bool? ?? false,
      maxParticipants: json['maxParticipants'] is num
          ? (json['maxParticipants'] as num).toInt()
          : 50,
      scheduledFor: json['scheduledFor'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  VibeRoomMessage messageFromJson(Map<String, dynamic> json) => VibeRoomMessage(
    id: json['id'] as String?,
    clientMessageId: json['clientMessageId'] as String?,
    sender: json['sender'] as String? ?? 'Member',
    avatar: json['avatar'] as String? ?? '',
    text: json['text'] as String? ?? '',
    time: _displayTime(json['time'] as String?),
    isMe: json['isMe'] as bool? ?? false,
  );

  String _displayTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.hour < 12 ? 'AM' : 'PM'}';
  }
}
