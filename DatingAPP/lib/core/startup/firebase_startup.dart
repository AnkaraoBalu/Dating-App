import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Shared initialization: push startup may wait, but the first frame never does.
class FirebaseStartup {
  static Future<void>? _initialization;
  static Future<void> initialize() => _initialization ??= _initialize();

  static Future<void> _initialize() async {
    final watch = Stopwatch()..start();
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 10));
      debugPrint('[Startup] Firebase ready in ${watch.elapsedMilliseconds}ms');
    } catch (error) {
      debugPrint(
        '[Push] Firebase unavailable after ${watch.elapsedMilliseconds}ms: $error',
      );
    }
  }
}
