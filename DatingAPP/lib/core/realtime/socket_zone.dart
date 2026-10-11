import 'dart:async';

/// Runs Socket.IO setup in a zone that drops one known library error.
///
/// socket_io_client 3.1.x closes its WebSocket a second time when the server
/// ends the connection, and the resulting `WebSocketConnectionClosed` escapes
/// as an uncaught async error. The disconnect itself is still reported through
/// the socket's normal `disconnect` event, so only that error is ignored;
/// anything else is passed on unchanged.
void runSocketZone(void Function() body) {
  final parent = Zone.current;
  runZonedGuarded(body, (error, stack) {
    // Matched by name: the type lives in package:web_socket, which the app
    // only depends on indirectly.
    if (error.runtimeType.toString() == 'WebSocketConnectionClosed') return;
    parent.handleUncaughtError(error, stack);
  });
}
