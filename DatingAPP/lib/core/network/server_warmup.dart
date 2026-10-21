import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Pings the API health check so a sleeping server starts booting while the
/// user is still on the splash, sign-in or resume path, instead of on the
/// first real request.
class ServerWarmup {
  ServerWarmup._();

  static Future<void>? _inFlight;

  /// Fire-and-forget; concurrent calls share one ping and errors are ignored.
  static Future<void> ping() =>
      _inFlight ??= _ping().whenComplete(() => _inFlight = null);

  static Future<void> _ping() async {
    final apiUrl = (dotenv.env['API_URL'] ?? dotenv.env['VITE_API_URL'] ?? '')
        .trim()
        .replaceFirst(RegExp(r'/$'), '');
    if (apiUrl.isEmpty) return;
    final client = http.Client();
    try {
      final watch = Stopwatch()..start();
      final response = await client
          .get(Uri.parse('$apiUrl/health'))
          .timeout(const Duration(seconds: 90));
      debugPrint(
        '[Network] Warm-up ${response.statusCode} in '
        '${watch.elapsedMilliseconds}ms.',
      );
    } catch (error) {
      debugPrint('[Network] Warm-up failed: $error');
    } finally {
      client.close();
    }
  }
}
