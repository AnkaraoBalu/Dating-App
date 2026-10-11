import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ProfileSetupApi {
  ProfileSetupApi({required this.baseUrl, required this.getSessionToken});

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client = http.Client();

  Future<Map<String, String>> _headers({bool json = true}) async => {
    'Authorization': 'Bearer ${await getSessionToken()}',
    if (json) 'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> load() async => _request(
    _client.get(Uri.parse('$baseUrl/profile'), headers: await _headers()),
  );

  Future<Map<String, dynamic>> update(Map<String, Object?> values) async =>
      _request(
        _client.patch(
          Uri.parse('$baseUrl/profile'),
          headers: await _headers(),
          body: jsonEncode(values),
        ),
      );

  Future<Map<String, dynamic>> savePrompts(
    List<Map<String, String>> prompts,
  ) async => _request(
    _client.put(
      Uri.parse('$baseUrl/profile/prompts'),
      headers: await _headers(),
      body: jsonEncode({'prompts': prompts}),
    ),
  );

  Future<Map<String, dynamic>> uploadPhoto(File file) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/profile/photos'))
          ..headers.addAll(await _headers(json: false))
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    return _decode(await http.Response.fromStream(streamed));
  }

  Future<Map<String, dynamic>> uploadPhotoWithProgress(
    File file, {
    required void Function(double progress) onProgress,
  }) async {
    final token = await getSessionToken();
    final boundary = 'matchify-${DateTime.now().microsecondsSinceEpoch}';
    final request =
        http.StreamedRequest('POST', Uri.parse('$baseUrl/profile/photos'))
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data; boundary=$boundary',
          });

    final fileLength = await file.length();
    final name = file.uri.pathSegments.isEmpty
        ? 'profile-photo.jpg'
        : file.uri.pathSegments.last;
    final prefix =
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="$name"\r\n'
        'Content-Type: application/octet-stream\r\n\r\n';
    const suffix = '\r\n';
    const closing = '--';
    request.contentLength =
        prefix.length +
        fileLength +
        suffix.length +
        boundary.length +
        closing.length +
        4;
    request.sink.add(utf8.encode(prefix));
    var sent = 0;
    await for (final chunk in file.openRead()) {
      request.sink.add(chunk);
      sent += chunk.length;
      onProgress(fileLength == 0 ? 0 : sent / fileLength);
    }
    request.sink
      ..add(utf8.encode(suffix))
      ..add(utf8.encode('--$boundary--\r\n'))
      ..close();
    final response = await request.send().timeout(const Duration(seconds: 90));
    return _decode(await http.Response.fromStream(response));
  }

  Future<Map<String, dynamic>> deletePhoto(String id) async => _request(
    _client.delete(
      Uri.parse('$baseUrl/profile/photos/$id'),
      headers: await _headers(),
    ),
  );

  Future<Map<String, dynamic>> reorderPhotos(List<String> photoIds) async =>
      _request(
        _client.patch(
          Uri.parse('$baseUrl/profile/photos/order'),
          headers: await _headers(),
          body: jsonEncode({'photoIds': photoIds}),
        ),
      );

  Future<Map<String, dynamic>> complete() async => _request(
    _client.post(
      Uri.parse('$baseUrl/profile/complete'),
      headers: await _headers(),
    ),
  );

  Future<Map<String, dynamic>> _request(Future<http.Response> response) async =>
      _decode(await response.timeout(const Duration(seconds: 20)));

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
      throw const FormatException('Unexpected response from Matchify API.');
    }
    return decoded;
  }
}
