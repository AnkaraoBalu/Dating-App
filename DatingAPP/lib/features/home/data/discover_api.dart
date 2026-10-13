import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'home_discover_data.dart';

class DiscoverApi extends ChangeNotifier {
  DiscoverApi({required this.baseUrl, required this.getSessionToken});

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client = http.Client();
  final Set<String> _likedUserIds = {};
  final Map<String, Future<bool>> _pendingLikes = {};
  bool _disposed = false;

  bool hasLiked(String userId) => _likedUserIds.contains(userId);

  Future<List<HomePerson>> discover({
    String mode = 'for_you',
    int minAge = 18,
    int maxAge = 70,
    String? gender,
    String? location,
    String? interest,
    List<String> interests = const [],
    double? latitude,
    double? longitude,
    int? radiusKm,
    bool onlineOnly = false,
    bool verifiedOnly = false,
    int limit = 60,
  }) async {
    final query = <String, String>{
      'mode': mode,
      'minAge': '$minAge',
      'maxAge': '$maxAge',
      'limit': '$limit',
    };
    void add(String key, Object? value) {
      if (value != null && value.toString().isNotEmpty) query[key] = '$value';
    }

    add('gender', gender);
    add('location', location);
    add('interest', interest);
    if (interests.isNotEmpty) query['interests'] = interests.join(',');
    add('latitude', latitude);
    add('longitude', longitude);
    add('radiusKm', radiusKm);
    if (onlineOnly) query['onlineOnly'] = 'true';
    if (verifiedOnly) query['verifiedOnly'] = 'true';
    final response = await _client
        .get(
          Uri.parse(
            '$baseUrl/profile/discover',
          ).replace(queryParameters: query),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (body is! List) throw const FormatException('Invalid people response.');
    return body
        .whereType<Map<String, dynamic>>()
        .map(_personFromJson)
        .where((person) => !hasLiked(person.id))
        .toList();
  }

  Future<bool> like(String userId) {
    return _pendingLikes.putIfAbsent(userId, () => _sendLike(userId));
  }

  Future<bool> _sendLike(String userId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/profile/discover/$userId/like'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));
      final data = _decode(response);
      if (data is! Map<String, dynamic> || data['isMatch'] is! bool) {
        throw const FormatException('Invalid like response.');
      }
      _likedUserIds.add(userId);
      if (!_disposed) notifyListeners();
      return data['isMatch'] as bool;
    } finally {
      _pendingLikes.remove(userId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }

  Future<void> pass(String userId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/profile/discover/$userId/pass'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  Future<void> recordActivity() async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/users/me/activity'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));
    _decode(response);
  }

  Future<Map<String, String>> _headers() async => {
    'Authorization': 'Bearer ${await getSessionToken()}',
    'Content-Type': 'application/json',
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

  HomePerson _personFromJson(Map<String, dynamic> json) {
    final photos = (json['photos'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final image =
        json['image'] as String? ?? (photos.isEmpty ? '' : photos.first);
    final prompts = (json['prompts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => {
            'question': item['question']?.toString() ?? '',
            'answer': item['answer']?.toString() ?? '',
          },
        )
        .toList();
    final tags = (json['tags'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();
    final distanceKm = (json['distanceKm'] as num?)?.toDouble();
    final rawDistance = json['distance']?.toString();
    return HomePerson(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Just2 member',
      age: (json['age'] as num?)?.toInt() ?? 18,
      image: image,
      photos: photos,
      prompts: prompts,
      distance:
          rawDistance ??
          (distanceKm == null ? 'Nearby' : '${distanceKm.round()} km away'),
      match: (json['match'] as num?)?.toInt() ?? 0,
      bio: json['bio']?.toString() ?? '',
      tags: tags,
      online: json['online'] == true,
      verified: json['verified'] == true,
      education: json['education']?.toString(),
      location: json['location']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      jobTitle: json['jobTitle']?.toString(),
      company: json['company']?.toString(),
      heightCm: (json['heightCm'] as num?)?.toInt(),
      zodiac: json['zodiac']?.toString(),
      languages: (json['languages'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
