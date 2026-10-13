import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/onboarding_profile.dart';

class OnboardingApi {
  OnboardingApi({required this.baseUrl, required this.getSessionToken});

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client = http.Client();

  Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await getSessionToken()}',
    'Content-Type': 'application/json',
  };

  Future<OnboardingProfile?> loadProfile() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/users/me'), headers: await _headers())
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
            'GET /users/me timed out after 30 seconds.',
          ),
        );
    final data = _decode(response);
    final profile = data['onboardingProfile'];
    if (profile == null) return null;
    return OnboardingProfile.fromJson({
      ...profile as Map<String, dynamic>,
      'username': data['username'],
    });
  }

  Future<void> updateName(String name) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/users/me/name'),
          headers: await _headers(),
          body: jsonEncode({'username': name.trim()}),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  Future<void> update(Map<String, Object?> changes) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/users/me/onboarding'),
          headers: await _headers(),
          body: jsonEncode(changes),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  Future<OnboardingProfile> updateLocationPermission(
    bool granted, {
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, Object?>{'locationPermissionGranted': granted};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/users/me/onboarding'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return OnboardingProfile.fromJson(_decode(response));
  }

  Future<void> complete() async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/users/me/onboarding/complete'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Object? decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      throw Exception(message ?? 'Request failed (${response.statusCode}).');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response from Just2 API.');
    }
    return decoded;
  }
}
