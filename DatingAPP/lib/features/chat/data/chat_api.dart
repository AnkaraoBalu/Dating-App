import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/chat_models.dart';

class ChatApi {
  ChatApi({
    required this.baseUrl,
    required this.getSessionToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client;

  Future<String> openConversation(String otherUserId) async {
    final response = await _client
        .post(
          Uri.parse(
            '$baseUrl/messages/conversations/${Uri.encodeComponent(otherUserId)}',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (body is! Map<String, dynamic> || body['id'] is! String) {
      throw const FormatException('Invalid conversation response.');
    }
    return body['id'] as String;
  }

  Future<Map<String, dynamic>> markConversationRead(
    String conversationId,
  ) async {
    final response = await _client
        .post(
          Uri.parse(
            '$baseUrl/messages/conversations/${Uri.encodeComponent(conversationId)}/read',
          ),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid read receipt response.');
    }
    return body;
  }

  Future<ChatMessagePage> loadMessages({
    required String conversationId,
    required String peerUserId,
    String? before,
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/messages/conversations/${Uri.encodeComponent(conversationId)}/messages',
    ).replace(queryParameters: {'limit': '$limit', 'before': ?before});
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    final rawItems = body is List
        ? body
        : body is Map<String, dynamic>
        ? body['items']
        : null;
    if (rawItems is! List) {
      throw const FormatException('Invalid messages response.');
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ChatMessage.fromJson(
            json,
            peerUserId: peerUserId,
            currentUserId: body is Map<String, dynamic>
                ? body['viewerId']?.toString()
                : null,
          ),
        )
        .toList();
    return ChatMessagePage(
      items: items,
      hasMore: body is Map<String, dynamic> && body['hasMore'] == true,
      nextCursor: body is Map<String, dynamic>
          ? body['nextCursor']?.toString()
          : null,
    );
  }

  Future<ChatMessage> sendImage({
    required String conversationId,
    required XFile image,
    required String clientMessageId,
    required String peerUserId,
    String caption = '',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/messages/conversations/${Uri.encodeComponent(conversationId)}/images',
      ),
    )..headers.addAll(await _headers(json: false));
    request.fields['clientMessageId'] = clientMessageId;
    request.fields['caption'] = caption;
    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final httpResponse = await http.Response.fromStream(
      streamed,
    ).timeout(const Duration(seconds: 30));
    final response = _decode(httpResponse);
    if (response is! Map<String, dynamic> || response['id'] is! String) {
      throw const FormatException('Invalid image message response.');
    }
    return ChatMessage.fromJson(response, peerUserId: peerUserId);
  }

  void close() => _client.close();

  Future<Map<String, String>> _headers({bool json = true}) async => {
    'Authorization':
        'Bearer ${await getSessionToken().timeout(const Duration(seconds: 10))}',
    if (json) 'Content-Type': 'application/json',
  };

  Object? _decode(http.Response response) {
    final Object? body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw Exception(message ?? 'Request failed (${response.statusCode}).');
    }
    return body;
  }
}
