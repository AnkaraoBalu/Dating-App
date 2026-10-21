import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/retrying_client.dart';
import '../models/vibe_room.dart';
import '../models/vibe_game.dart';

class VibeRoomsApi {
  VibeRoomsApi({
    required this.baseUrl,
    required this.getSessionToken,
    this.currentUserImage,
  });

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final String? currentUserImage;

  // Shared so GETs retry through a cold start or a brief network drop.
  static final http.Client _client = RetryingClient();

  Future<String?> loadCurrentUserImage() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/profile'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) return null;
    final profile = decoded['profile'] is Map<String, dynamic>
        ? decoded['profile'] as Map<String, dynamic>
        : decoded;
    final photos = profile['photos'] as List<dynamic>? ?? const [];
    for (final photo in photos) {
      final image = photo is Map
          ? (photo['secureUrl'] ?? photo['url'])?.toString()
          : photo?.toString();
      if (image != null && image.trim().isNotEmpty) return image;
    }
    final image =
        profile['image']?.toString() ?? profile['avatarUrl']?.toString();
    return image == null || image.trim().isEmpty ? null : image;
  }

  Future<List<VibeRoom>> listRooms({String? categoryId}) async {
    final query = <String, String>{
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };
    final uri = Uri.parse(
      '$baseUrl/vibe-rooms',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client
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

  /// Rooms the signed-in member has joined, formatted as group chats.
  Future<List<VibeRoomChat>> listChats() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/vibe-rooms/chats'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const FormatException('Invalid vibe room chats response.');
    }
    return decoded.whereType<Map<String, dynamic>>().map((json) {
      final rawRoom = json['room'];
      final rawMessage = json['lastMessage'];
      if (rawRoom is! Map<String, dynamic>) {
        throw const FormatException('Invalid vibe room chat.');
      }
      VibeRoomChatMessage? lastMessage;
      if (rawMessage is Map<String, dynamic>) {
        lastMessage = VibeRoomChatMessage(
          text: rawMessage['text']?.toString() ?? '',
          sender: rawMessage['sender']?.toString() ?? 'Member',
          isMe: rawMessage['isMe'] == true,
          kind: rawMessage['kind']?.toString() ?? 'text',
        );
      }
      return VibeRoomChat(
        room: _roomFromJson(rawRoom),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
        lastActivityAt: DateTime.tryParse(
          json['lastActivityAt']?.toString() ?? '',
        )?.toLocal(),
        lastMessage: lastMessage,
      );
    }).toList();
  }

  Future<void> markChatRead(String roomId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/read'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    _decode(response);
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

  /// Requests a short-lived LiveKit token for an active room member.
  /// The API secret remains on the backend and is never sent to this app.
  Future<VibeVoiceCredentials> createVoiceToken(String roomId) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/voice-token',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice room credentials.');
    }
    final credentials = VibeVoiceCredentials.fromJson(decoded);
    if (credentials.serverUrl.isEmpty ||
        credentials.participantToken.isEmpty ||
        credentials.identity.isEmpty) {
      throw const FormatException('Voice room credentials are incomplete.');
    }
    return credentials;
  }

  /// Host-only: mutes another member's microphone in the room's voice call.
  Future<void> muteVoiceParticipant(String roomId, String participantId) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/voice/participants/${Uri.encodeComponent(participantId)}/mute',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    _decode(response);
  }

  Future<List<VibeRoomMessage>> listMessages(
    String roomId, {
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/messages',
    ).replace(queryParameters: {'limit': '$limit'});
    final response = await _client
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

  Future<VibeRoomMessage> sendVoiceMessage({
    required String roomId,
    required String clientMessageId,
    required String path,
    required int durationMs,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/messages/voice',
            ),
          )
          ..headers.addAll((await _headers())..remove('Content-Type'))
          ..fields['clientMessageId'] = clientMessageId
          ..fields['durationMs'] = '$durationMs'
          ..files.add(await http.MultipartFile.fromPath('file', path));
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(const Duration(seconds: 30));
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid sent voice message.');
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

  Future<VibeGameSession?> getActiveGame(String roomId) async {
    final response = await _client
        .get(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/games/active',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    final decoded = _decode(response);
    // Nest may send an empty body when there is no active session. Never
    // turn that into a default session with an empty ID and zero players.
    if (decoded == null || (decoded is Map && decoded.isEmpty)) return null;
    final data = _asMap(decoded);
    final session = VibeGameSession.fromJson(data);
    return session.isWaiting || session.isPlaying ? session : null;
  }

  Future<VibeGameSession> createGame(
    String roomId,
    String gameType, {
    Map<String, dynamic>? setup,
  }) async {
    final payload = <String, dynamic>{'gameType': gameType};
    if (setup != null) payload['setup'] = setup;
    final response = await http
        .post(
          Uri.parse('$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/games'),
          headers: await _headers(),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    return VibeGameSession.fromJson(_asMap(_decode(response)));
  }

  Future<VibeGameSession> getGame(String roomId, String sessionId) async {
    final response = await _client
        .get(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/games/${Uri.encodeComponent(sessionId)}',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return VibeGameSession.fromJson(_asMap(_decode(response)));
  }

  Future<VibeGameSession> joinGame(String roomId, String sessionId) =>
      _gameAction(roomId, sessionId, 'join');

  Future<VibeGameSession> startGame(String roomId, String sessionId) =>
      _gameAction(roomId, sessionId, 'start');

  Future<VibeGameSession> leaveGame(String roomId, String sessionId) =>
      _gameAction(roomId, sessionId, 'leave');

  Future<VibeGameSession> answerGame({
    required String roomId,
    required String sessionId,
    required int questionIndex,
    required int choiceIndex,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/games/${Uri.encodeComponent(sessionId)}/answers',
          ),
          headers: await _headers(),
          body: jsonEncode({
            'questionIndex': questionIndex,
            'choiceIndex': choiceIndex,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return VibeGameSession.fromJson(_asMap(_decode(response)));
  }

  Future<VibeGameSession> _gameAction(
    String roomId,
    String sessionId,
    String action,
  ) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/vibe-rooms/${Uri.encodeComponent(roomId)}/games/${Uri.encodeComponent(sessionId)}/$action',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return VibeGameSession.fromJson(_asMap(_decode(response)));
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic> &&
        value['id'] is String &&
        (value['id'] as String).trim().isNotEmpty &&
        value['roomId'] is String &&
        (value['roomId'] as String).trim().isNotEmpty &&
        value['gameType'] is String &&
        (value['gameType'] as String).trim().isNotEmpty &&
        const [
          'waiting',
          'playing',
          'completed',
          'cancelled',
        ].contains(value['status'])) {
      return value;
    }
    throw const FormatException('Invalid game response.');
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
              sender: message['isMe'] == true
                  ? 'You'
                  : message['sender'] as String? ?? 'Member',
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
    sender: json['isMe'] == true
        ? 'You'
        : json['sender'] as String? ?? 'Member',
    avatar: json['avatar'] as String? ?? '',
    text: json['text'] as String? ?? '',
    time: _displayTime(json['time'] as String?),
    isMe: json['isMe'] as bool? ?? false,
    kind: json['kind'] as String? ?? 'text',
    mediaUrl: json['mediaUrl'] as String?,
    durationMs: (json['durationMs'] as num?)?.toInt(),
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
