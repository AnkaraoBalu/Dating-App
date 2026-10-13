import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/authed_socket_connection.dart';
import '../models/vibe_room.dart';
import 'vibe_rooms_api.dart';

class VibeRoomGameEvent {
  const VibeRoomGameEvent({
    required this.sessionId,
    required this.change,
    required this.title,
  });
  final String sessionId;
  final String change;
  final String title;
}

/// Live chat for one Vibe room.
///
/// Messages are still sent over REST ([VibeRoomsApi.sendMessage]); the server
/// then pushes every saved message to the room's members here. After each
/// (re)join, [joined] fires so the screen reloads history and fills any gap
/// from while it was offline.
class VibeRoomLiveService {
  VibeRoomLiveService({required this.api, required this.roomId})
    : _connection = AuthedSocketConnection(
        baseUrl: api.baseUrl,
        getSessionToken: api.getSessionToken,
      ) {
    _connection
      ..onReady((_) => _connection.emit('vibe:join', {'roomId': roomId}))
      ..on('vibe:joined', (data) {
        if (!_isThisRoom(data)) return;
        live.value = true;
        _add(_joined, null);
      })
      ..on('vibe:error', (data) {
        if (_isThisRoom(data)) live.value = false;
      })
      ..on('vibe:member', (data) {
        if (!_isThisRoom(data) || data['event'] != 'joined') return;
        final name = data['name']?.toString().trim();
        _add(_memberJoined, name == null || name.isEmpty ? 'Someone' : name);
      })
      ..on('vibe:message', (data) {
        if (!_isThisRoom(data)) return;
        _add(_messages, api.messageFromJson(Map<String, dynamic>.from(data)));
      })
      ..on('vibe:game', (data) {
        if (!_isThisRoom(data) || data is! Map) return;
        final sessionId = data['sessionId']?.toString();
        if (sessionId == null || sessionId.isEmpty) return;
        _add(
          _gameEvents,
          VibeRoomGameEvent(
            sessionId: sessionId,
            change: data['change']?.toString() ?? 'updated',
            title: data['title']?.toString() ?? 'Room game',
          ),
        );
      });
    _connection.connected.addListener(_connectionChanged);
  }

  final VibeRoomsApi api;
  final String roomId;
  final AuthedSocketConnection _connection;
  final StreamController<VibeRoomMessage> _messages =
      StreamController<VibeRoomMessage>.broadcast();
  final StreamController<void> _joined = StreamController<void>.broadcast();
  final StreamController<String> _memberJoined =
      StreamController<String>.broadcast();
  final StreamController<VibeRoomGameEvent> _gameEvents =
      StreamController<VibeRoomGameEvent>.broadcast();

  /// True while this room's messages are being pushed live.
  final ValueNotifier<bool> live = ValueNotifier(false);

  Stream<VibeRoomMessage> get messages => _messages.stream;
  Stream<void> get joined => _joined.stream;

  /// Names of members who join while this room is open.
  Stream<String> get memberJoined => _memberJoined.stream;
  Stream<VibeRoomGameEvent> get gameEvents => _gameEvents.stream;

  void connect() => _connection.connect();

  bool _isThisRoom(dynamic data) => data is Map && data['roomId'] == roomId;

  void _connectionChanged() {
    if (!_connection.connected.value) live.value = false;
  }

  void _add<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }

  Future<void> dispose() async {
    _connection.emit('vibe:leave', {'roomId': roomId});
    _connection.connected.removeListener(_connectionChanged);
    _connection.dispose();
    live.dispose();
    await _messages.close();
    await _joined.close();
    await _memberJoined.close();
    await _gameEvents.close();
  }
}
