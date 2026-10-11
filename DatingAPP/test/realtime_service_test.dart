import 'dart:convert';
import 'dart:io';

import 'package:dating_app/core/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

Future<void> until(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for realtime');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<String> startFixture() async {
  final process = await Process.start('node', [
    '../backend/test/fixtures/chat-socket-server.cjs',
  ]);
  addTearDown(() async {
    process.kill();
    await process.exitCode;
  });
  final port = await process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .first;
  return 'http://127.0.0.1:$port';
}

void main() {
  test(
    'delivers inbox, like and match events only to the addressed member',
    () async {
      final baseUrl = await startFixture();
      RealtimeService connect(String user) {
        final realtime = RealtimeService(
          baseUrl: '$baseUrl/api/v1',
          getSessionToken: () async => '$user:1',
        )..connect();
        addTearDown(realtime.dispose);
        return realtime;
      }

      final zoya = connect('zoya');
      final arav = connect('arav');
      final zoyaEvents = <RealtimeEvent>[];
      final aravEvents = <RealtimeEvent>[];
      zoya.events.listen(zoyaEvents.add);
      arav.events.listen(aravEvents.add);
      await until(() => zoya.connected.value && arav.connected.value);

      Future<void> notify(String user, String event, [Object? payload]) =>
          http.get(
            Uri.parse('$baseUrl/fixture/notify').replace(
              queryParameters: {
                'user': user,
                'event': event,
                'payload': jsonEncode(payload ?? {}),
              },
            ),
          );

      await notify('zoya', 'like:new');
      await notify('zoya', 'inbox:changed', {'conversationId': 'c1'});
      await notify('zoya', 'match:new', {
        'userId': 'arav',
        'initiatedByYou': false,
      });
      await notify('arav', 'match:new', {
        'userId': 'zoya',
        'initiatedByYou': true,
      });
      await until(() => zoyaEvents.length == 3 && aravEvents.length == 1);

      expect(zoyaEvents.map((e) => e.type), [
        RealtimeEventType.likeReceived,
        RealtimeEventType.inboxChanged,
        RealtimeEventType.matched,
      ]);
      expect(zoyaEvents[1].conversationId, 'c1');
      expect(zoyaEvents[2].userId, 'arav');
      expect(zoyaEvents[2].initiatedByYou, isFalse);
      expect(aravEvents.single.userId, 'zoya');
      expect(aravEvents.single.initiatedByYou, isTrue);
    },
  );

  test(
    'reconnects after network drops and server disconnects, then resyncs',
    () async {
      final baseUrl = await startFixture();
      var tokenRequests = 0;
      final realtime = RealtimeService(
        baseUrl: '$baseUrl/api/v1',
        getSessionToken: () async => 'zoya:${++tokenRequests}',
      )..connect();
      addTearDown(realtime.dispose);
      final events = <RealtimeEventType>[];
      realtime.events.listen((event) => events.add(event.type));
      await until(() => realtime.connected.value);
      expect(events, isEmpty);

      // Network drop: Socket.IO reconnects by itself with a fresh token.
      await http.get(Uri.parse('$baseUrl/fixture/drop?user=zoya'));
      await until(() => !realtime.connected.value);
      await until(() => realtime.connected.value);
      expect(events, [RealtimeEventType.resynced]);

      // Server-initiated disconnect: the service schedules its own retry.
      await http.get(Uri.parse('$baseUrl/fixture/kick?user=zoya'));
      await until(() => !realtime.connected.value);
      await until(() => realtime.connected.value, seconds: 10);
      expect(events, [RealtimeEventType.resynced, RealtimeEventType.resynced]);
      expect(tokenRequests, 3);
    },
  );
}
