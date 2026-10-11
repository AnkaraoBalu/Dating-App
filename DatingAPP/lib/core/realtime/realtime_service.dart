import 'dart:async';

import 'package:flutter/foundation.dart';

import 'authed_socket_connection.dart';

enum RealtimeEventType {
  /// A conversation got a new message or was read; reload the chat list.
  inboxChanged,

  /// Someone liked the signed-in member.
  likeReceived,

  /// A like became mutual. [RealtimeEvent.userId] is the other member.
  matched,

  /// The connection came back after a drop. Events may have been missed while
  /// offline, so listeners should reload everything they show.
  resynced,
}

class RealtimeEvent {
  const RealtimeEvent(
    this.type, {
    this.conversationId,
    this.userId,
    this.initiatedByYou = false,
  });

  final RealtimeEventType type;
  final String? conversationId;
  final String? userId;

  /// For [RealtimeEventType.matched]: this member's like completed the match,
  /// so the app that sent it is already showing the celebration.
  final bool initiatedByYou;
}

/// One Socket.IO connection for the signed-in session (owned by HomeScreen).
///
/// The server puts it in the member's private room and pushes inbox, like and
/// match events there. Payloads only say what changed; screens reload details
/// over REST. Chat screens keep their own conversation connection
/// (`ChatSocketService`) for message delivery.
class RealtimeService {
  RealtimeService({
    required String baseUrl,
    required Future<String> Function() getSessionToken,
  }) : _connection = AuthedSocketConnection(
         baseUrl: baseUrl,
         getSessionToken: getSessionToken,
       ) {
    _connection
      ..onReady((reconnected) {
        if (reconnected) _add(const RealtimeEvent(RealtimeEventType.resynced));
      })
      ..on('inbox:changed', (data) {
        _add(
          RealtimeEvent(
            RealtimeEventType.inboxChanged,
            conversationId: data is Map
                ? data['conversationId']?.toString()
                : null,
          ),
        );
      })
      ..on('like:new', (_) {
        _add(const RealtimeEvent(RealtimeEventType.likeReceived));
      })
      ..on('match:new', (data) {
        _add(
          RealtimeEvent(
            RealtimeEventType.matched,
            userId: data is Map ? data['userId']?.toString() : null,
            initiatedByYou: data is Map && data['initiatedByYou'] == true,
          ),
        );
      });
  }

  final AuthedSocketConnection _connection;
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _events.stream;

  /// True while the server has authenticated this connection.
  ValueListenable<bool> get connected => _connection.connected;

  void connect() => _connection.connect();

  void _add(RealtimeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> dispose() async {
    _connection.dispose();
    await _events.close();
  }
}
