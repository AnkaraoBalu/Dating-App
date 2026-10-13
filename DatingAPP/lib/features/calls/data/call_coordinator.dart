import 'dart:async';

import '../models/voice_call.dart';

/// App-wide call state: forwards live call updates to the open call screen
/// and remembers which call is on screen, so a call is never shown twice
/// (for example from both its live event and its push notification).
class CallCoordinator {
  CallCoordinator._();

  static final instance = CallCoordinator._();

  final _updates = StreamController<VoiceCallUpdate>.broadcast();

  /// The call whose screen is open, if any.
  String? activeCallId;

  /// True while any call screen is open, including one still starting.
  bool screenOpen = false;

  Stream<VoiceCallUpdate> get updates => _updates.stream;

  void publish(VoiceCallUpdate update) => _updates.add(update);
}
