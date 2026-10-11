import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match_model.dart';

class MatchApi {
  MatchApi({required this.baseUrl, required this.getSessionToken});

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client = http.Client();

  void dispose() => _client.close();

  Future<List<MatchRecord>> loadMatches({String? query}) async {
    final uri = Uri.parse('$baseUrl/profile/matches').replace(
      queryParameters: query == null || query.isEmpty
          ? null
          : {'search': query},
    );
    final response = await _client.get(uri, headers: await _headers());
    final body = _decode(response);
    final records = body is List
        ? body
        : body is Map<String, dynamic>
        ? body['matches']
        : null;
    if (records is! List) {
      throw const FormatException('Invalid matches response.');
    }
    return records
        .whereType<Map<String, dynamic>>()
        .map(MatchRecord.fromJson)
        .toList();
  }

  Future<List<MatchRecord>> loadConversations({String? query}) async {
    final uri = Uri.parse('$baseUrl/messages/conversations').replace(
      queryParameters: query == null || query.isEmpty
          ? null
          : {'search': query},
    );
    final response = await _client.get(uri, headers: await _headers());
    final body = _decode(response);
    if (body is! List) {
      throw const FormatException('Invalid conversations response.');
    }
    return body
        .whereType<Map<String, dynamic>>()
        .map(MatchRecord.fromJson)
        .toList();
  }

  Future<void> markConversationRead(String conversationId) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/messages/conversations/${Uri.encodeComponent(conversationId)}/read',
      ),
      headers: await _headers(),
    );
    _decode(response);
  }

  Future<bool> sendLike(String userId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/profile/discover/$userId/like'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decode(response);
    if (body is! Map<String, dynamic> || body['isMatch'] is! bool) {
      throw const FormatException('Invalid like response.');
    }
    return body['isMatch'] as bool;
  }

  Future<List<MatchRecord>> loadIncomingLikes() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/profile/likes/received'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decode(response);
    if (body is! List) {
      throw const FormatException('Invalid incoming likes response.');
    }
    return body
        .whereType<Map<String, dynamic>>()
        .map(MatchRecord.fromIncomingLike)
        .toList();
  }

  Future<String?> loadCurrentUserImage() async =>
      (await loadCurrentUserPhoto()).image;

  Future<({String? image, String? name})> loadCurrentUserPhoto() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/profile'), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final body = _decode(response);
    if (body is! Map<String, dynamic>) return (image: null, name: null);
    final profile = body['profile'] is Map<String, dynamic>
        ? body['profile'] as Map<String, dynamic>
        : body;
    final user = profile['user'];
    final name = user is Map
        ? (user['username'] ?? user['firstName'])?.toString()
        : null;
    final photos = profile['photos'] as List<dynamic>? ?? const [];
    for (final photo in photos) {
      final url = photo is Map
          ? (photo['secureUrl'] ?? photo['url'])?.toString()
          : photo?.toString();
      if (url != null && url.trim().isNotEmpty) return (image: url, name: name);
    }
    final image =
        profile['image']?.toString() ?? profile['avatarUrl']?.toString();
    return (
      image: image == null || image.trim().isEmpty ? null : image,
      name: name,
    );
  }

  Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await getSessionToken()}',
    'Content-Type': 'application/json',
  };

  Object? _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw Exception(message ?? 'Request failed (${response.statusCode}).');
    }
    return body;
  }
}
