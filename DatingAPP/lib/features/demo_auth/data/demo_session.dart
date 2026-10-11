import 'package:flutter/foundation.dart';

class DemoSession {
  const DemoSession({required this.accessToken, required this.username});

  final String accessToken;
  final String username;

  static final ValueNotifier<DemoSession?> current =
      ValueNotifier<DemoSession?>(null);

  static void activate(DemoSession session) => current.value = session;
  static void clear() => current.value = null;
}
