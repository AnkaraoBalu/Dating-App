import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../../core/network/retrying_client.dart';

/// Why a member is being reported. Values match the backend's report reasons.
enum ReportReason {
  fakeProfile('fake_profile', 'Fake profile or catfishing'),
  inappropriatePhotos('inappropriate_photos', 'Inappropriate photos'),
  harassment('harassment', 'Harassment or threats'),
  offensiveMessages('offensive_messages', 'Offensive messages'),
  scamOrSpam('scam_or_spam', 'Scam, spam or selling'),
  underage('underage', 'May be under 18'),
  other('other', 'Something else');

  const ReportReason(this.value, this.label);
  final String value;
  final String label;
}

/// Block, unmatch and report another member.
class SafetyApi {
  SafetyApi({
    required this.baseUrl,
    required this.getSessionToken,
    http.Client? client,
  }) : _client = client ?? RetryingClient();

  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final http.Client _client;

  Future<void> block(String userId) => _post(userId, 'block');

  Future<void> unmatch(String userId) => _post(userId, 'unmatch');

  /// Reporting also blocks the member for the reporter.
  Future<void> report(
    String userId, {
    required ReportReason reason,
    String? details,
    required String source,
  }) => _post(userId, 'report', {
    'reason': reason.value,
    if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
    'source': source,
  });

  Future<void> _post(
    String userId,
    String action, [
    Map<String, Object?>? body,
  ]) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/safety/users/$userId/$action'),
          headers: {
            'Authorization': 'Bearer ${await getSessionToken()}',
            'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    final message = decoded is Map ? decoded['message'] : null;
    throw Exception(
      message is String ? message : 'Request failed (${response.statusCode}).',
    );
  }
}
