import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/authed_socket_connection.dart';
import 'vibe_rooms_api.dart';

class VibeGameChange {
  const VibeGameChange({required this.sessionId, required this.change});
  final String sessionId;
  final String change;
}

/// Live invalidations for game sessions in one room. The server broadcasts no
/// private answers; clients reload the authenticated state over REST.
class VibeGameLiveService {
  VibeGameLiveService({required this.api, required this.roomId})
    : _connection = AuthedSocketConnection(
        baseUrl: api.baseUrl,
        getSessionToken: api.getSessionToken,
      ) {
    _connection
      ..onReady((reconnected) {
        _connection.emit('vibe:join', {'roomId': roomId});
        if (reconnected && !_changes.isClosed) {
          _changes.add(
            const VibeGameChange(sessionId: '', change: 'reconnected'),
          );
        }
      })
      ..on('vibe:joined', (data) {
        if (_isThisRoom(data)) {
          live.value = true;
          if (!_changes.isClosed) {
            _changes.add(const VibeGameChange(sessionId: '', change: 'joined'));
          }
        }
      })
      ..on('vibe:error', (data) {
        if (_isThisRoom(data)) live.value = false;
      })
      ..on('vibe:game', (data) {
        if (!_isThisRoom(data) || data is! Map) return;
        final sessionId = data['sessionId']?.toString();
        if (sessionId == null || sessionId.isEmpty) return;
        final change = data['change']?.toString() ?? 'updated';
        if (!_changes.isClosed) {
          _changes.add(VibeGameChange(sessionId: sessionId, change: change));
        }
      });
    _connection.connected.addListener(_connectionChanged);
  }

  final VibeRoomsApi api;
  final String roomId;
  final AuthedSocketConnection _connection;
  final StreamController<VibeGameChange> _changes =
      StreamController<VibeGameChange>.broadcast();
  final ValueNotifier<bool> live = ValueNotifier(false);

  Stream<VibeGameChange> get changes => _changes.stream;
  void connect() => _connection.connect();

  bool _isThisRoom(dynamic data) => data is Map && data['roomId'] == roomId;

  void _connectionChanged() {
    if (!_connection.connected.value) live.value = false;
  }

  Future<void> dispose() async {
    _connection.emit('vibe:leave', {'roomId': roomId});
    _connection.connected.removeListener(_connectionChanged);
    _connection.dispose();
    live.dispose();
    await _changes.close();
  }
}
