import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'socket_zone.dart';

/// A Socket.IO connection to the Matchify API that stays authenticated.
///
/// - Sends a fresh session token on every (re)connect.
/// - Reports [connected] only after the server's `chat:ready`, i.e. once it has
///   mapped the token to a member.
/// - Socket.IO retries network drops itself; a disconnect the server initiates
///   (for example a rejected token) is retried here with backoff.
///
/// Register handlers with [on] and [onReady] before calling [connect]; they are
/// re-attached whenever the underlying socket is recreated.
class AuthedSocketConnection {
  AuthedSocketConnection({
    required String baseUrl,
    required this.getSessionToken,
  }) : _origin = Uri.parse(
         baseUrl,
       ).replace(path: '', query: null, fragment: null).toString();

  final Future<String> Function() getSessionToken;
  final String _origin;
  final Map<String, void Function(dynamic data)> _handlers = {};
  final List<void Function(bool reconnected)> _readyHandlers = [];

  /// True while the server has authenticated this connection.
  final ValueNotifier<bool> connected = ValueNotifier(false);

  socket_io.Socket? _socket;
  Timer? _retry;
  int _failedAttempts = 0;
  bool _connectedBefore = false;
  bool _disposed = false;

  bool get disposed => _disposed;

  void on(String event, void Function(dynamic data) handler) {
    _handlers[event] = handler;
  }

  /// Called after each successful authentication. `reconnected` is true for
  /// every connection after the first, when events may have been missed.
  void onReady(void Function(bool reconnected) handler) {
    _readyHandlers.add(handler);
  }

  /// Sends only while connected; returns whether the event was sent.
  bool emit(String event, Object? payload) {
    final socket = _socket;
    if (!connected.value || socket == null) return false;
    socket.emit(event, payload);
    return true;
  }

  void connect() {
    if (_disposed || _socket != null) return;
    runSocketZone(_open);
  }

  void _open() {
    final socket = socket_io.io(_origin, {
      'transports': ['websocket'],
      'autoConnect': false,
      // Never share a cached manager with another account's connection.
      'forceNew': true,
      'multiplex': false,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 30000,
    });
    _socket = socket;
    socket.auth = (Function callback) async {
      try {
        final token = await getSessionToken().timeout(
          const Duration(seconds: 10),
        );
        if (!_disposed && identical(_socket, socket)) {
          callback({'token': token});
        }
      } catch (_) {
        if (identical(_socket, socket)) _restartLater();
      }
    };
    socket.on('chat:ready', (_) {
      if (!identical(_socket, socket) || _disposed) return;
      _failedAttempts = 0;
      connected.value = true;
      final reconnected = _connectedBefore;
      _connectedBefore = true;
      for (final handler in List.of(_readyHandlers)) {
        handler(reconnected);
      }
    });
    _handlers.forEach((event, handler) {
      socket.on(event, (data) {
        if (identical(_socket, socket) && !_disposed) handler(data);
      });
    });
    socket.onDisconnect((reason) {
      if (!identical(_socket, socket)) return;
      _setDisconnected();
      if (reason == 'io server disconnect') _restartLater();
    });
    socket.onConnectError((_) {
      if (identical(_socket, socket)) _setDisconnected();
    });
    socket.connect();
  }

  void _setDisconnected() {
    if (!_disposed) connected.value = false;
  }

  void _restartLater() {
    if (_disposed) return;
    _closeSocket();
    _retry?.cancel();
    final seconds = math.min(60, 2 << math.min(_failedAttempts, 5));
    _failedAttempts++;
    _retry = Timer(Duration(seconds: seconds), connect);
  }

  void _closeSocket() {
    final socket = _socket;
    _socket = null;
    _setDisconnected();
    socket
      ?..clearListeners()
      ..disconnect()
      ..dispose();
  }

  void dispose() {
    if (_disposed) return;
    _retry?.cancel();
    _closeSocket();
    _disposed = true;
    connected.dispose();
  }
}
