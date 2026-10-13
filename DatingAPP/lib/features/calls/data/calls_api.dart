import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/voice_call.dart';

class CallsApi {
  CallsApi({required this.baseUrl, required this.getSessionToken});

  final String baseUrl;
  final Future<String> Function() getSessionToken;

  /// Rings the other member of [conversationId]; returns the caller's join.
  Future<VoiceCall> start(String conversationId) =>
      _post('', body: {'conversationId': conversationId});

  Future<VoiceCall> get(String callId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/calls/${Uri.encodeComponent(callId)}'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _call(response);
  }

  Future<VoiceCall> accept(String callId) => _post('/$callId/accept');

  Future<VoiceCall> decline(String callId) => _post('/$callId/decline');

  Future<VoiceCall> end(String callId) => _post('/$callId/end');

  Future<VoiceCall> _post(String path, {Map<String, String>? body}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/calls$path'),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _call(response);
  }

  VoiceCall _call(http.Response response) {
    final Object? body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw CallException(
        message?.toString() ?? 'Request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid call response.');
    }
    return VoiceCall.fromJson(body);
  }

  Future<Map<String, String>> _headers() async => {
    'Authorization':
        'Bearer ${await getSessionToken().timeout(const Duration(seconds: 10))}',
    'Content-Type': 'application/json',
  };
}

class CallException implements Exception {
  const CallException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 409: one of the members is already on a call.
  bool get busy => statusCode == 409;

  @override
  String toString() => message;
}
