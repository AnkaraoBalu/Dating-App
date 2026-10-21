import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../../core/network/retrying_client.dart';

/// Registers this phone for push notifications with the Just2 API.
class NotificationsApi {
  NotificationsApi({
    required this.baseUrl,
    required this.getSessionToken,
    http.Client? client,
  }) : _client = client ?? RetryingClient();

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client;

  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/notifications/devices'),
          headers: await _headers(),
          body: jsonEncode({'token': token, 'platform': platform}),
        )
        .timeout(const Duration(seconds: 20));
    _check(response);
  }

  Future<void> removeDevice(String token) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/notifications/devices'),
          headers: await _headers(),
          body: jsonEncode({'token': token}),
        )
        .timeout(const Duration(seconds: 10));
    _check(response);
  }

  void close() => _client.close();

  Future<Map<String, String>> _headers() async => {
    'Authorization':
        'Bearer ${await getSessionToken().timeout(const Duration(seconds: 10))}',
    'Content-Type': 'application/json',
  };

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    final message = body is Map<String, dynamic> ? body['message'] : null;
    throw Exception(message ?? 'Request failed (${response.statusCode}).');
  }
}
