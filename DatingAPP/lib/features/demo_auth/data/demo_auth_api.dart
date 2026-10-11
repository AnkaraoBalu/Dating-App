import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DemoAccount {
  const DemoAccount({required this.username, required this.gender});

  final String username;
  final String gender;

  factory DemoAccount.fromJson(Map<String, dynamic> json) => DemoAccount(
    username: json['username'] as String,
    gender: json['gender'] as String? ?? 'unknown',
  );
}

class DemoAuthApi {
  DemoAuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl =>
      (dotenv.env['API_URL'] ?? '').trim().replaceFirst(RegExp(r'/$'), '');

  Future<List<DemoAccount>> listAccounts() async {
    final response = await _client
        .get(Uri.parse('${_requireBaseUrl()}/auth/demo/users'))
        .timeout(const Duration(seconds: 15));
    final body = _decode(response);
    return (body['users'] as List<dynamic>)
        .map((user) => DemoAccount.fromJson(user as Map<String, dynamic>))
        .toList();
  }

  Future<String> login(String username) async {
    final response = await _client
        .post(
          Uri.parse('${_requireBaseUrl()}/auth/demo/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username}),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(response)['accessToken'] as String;
  }

  String _requireBaseUrl() {
    if (_baseUrl.isEmpty) throw Exception('Set API_URL in DatingAPP/.env.');
    return _baseUrl;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Object? value = response.body.isEmpty
        ? {}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = value is Map<String, dynamic> ? value['message'] : null;
      throw Exception(message ?? 'Demo login failed (${response.statusCode}).');
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response from Matchify API.');
    }
    return value;
  }
}
