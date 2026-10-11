import 'dart:convert';
import 'dart:io';

import 'package:dating_app/features/vibes/data/vibe_room_live_service.dart';
import 'package:dating_app/features/vibes/data/vibe_rooms_api.dart';
import 'package:dating_app/features/vibes/models/vibe_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

Future<void> until(bool Function() condition, {int seconds = 8}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for live room');
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
  late String baseUrl;

  VibeRoomLiveService join(String user, String roomId) {
    final live = VibeRoomLiveService(
      api: VibeRoomsApi(
        baseUrl: '$baseUrl/api/v1',
        getSessionToken: () async => '$user:1',
      ),
      roomId: roomId,
    )..connect();
    addTearDown(live.dispose);
    return live;
  }

  Future<void> push(String room, String sender, String id, String text) =>
      http.get(
        Uri.parse('$baseUrl/fixture/vibe-message').replace(
          queryParameters: {
            'room': room,
            'sender': sender,
            'id': id,
            'client': 'client-$id',
            'text': text,
          },
        ),
      );

  setUp(() async => baseUrl = await startFixture());

  test('room members receive pushed messages with their own isMe', () async {
    final zoya = join('zoya', 'r1');
    final arav = join('arav', 'r1');
    final elsewhere = join('ira', 'r2');
    final zoyaMessages = <VibeRoomMessage>[];
    final aravMessages = <VibeRoomMessage>[];
    final otherRoom = <VibeRoomMessage>[];
    var zoyaJoins = 0;
    zoya.messages.listen(zoyaMessages.add);
    arav.messages.listen(aravMessages.add);
    elsewhere.messages.listen(otherRoom.add);
    zoya.joined.listen((_) => zoyaJoins++);
    await until(
      () => zoya.live.value && arav.live.value && elsewhere.live.value,
    );
    expect(zoyaJoins, 1);

    await push('r1', 'arav', 'm1', 'Hello room');
    await until(() => zoyaMessages.length == 1 && aravMessages.length == 1);
    expect(zoyaMessages.single.text, 'Hello room');
    expect(zoyaMessages.single.isMe, isFalse);
    expect(aravMessages.single.isMe, isTrue);
    expect(aravMessages.single.clientMessageId, 'client-m1');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(otherRoom, isEmpty);
  });

  test('a room the member may not view never goes live', () async {
    final outsider = join('zoya', 'forbidden');
    final received = <VibeRoomMessage>[];
    outsider.messages.listen(received.add);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(outsider.live.value, isFalse);
    await push('forbidden', 'arav', 'm2', 'Secret');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(received, isEmpty);
  });

  test('after a drop it rejoins and asks the screen to reload', () async {
    final zoya = join('zoya', 'r1');
    var joins = 0;
    zoya.joined.listen((_) => joins++);
    await until(() => joins == 1);
    await http.get(Uri.parse('$baseUrl/fixture/drop?user=zoya'));
    await until(() => !zoya.live.value);
    await until(() => joins == 2 && zoya.live.value);
    final received = <VibeRoomMessage>[];
    zoya.messages.listen(received.add);
    await push('r1', 'arav', 'm3', 'Back online');
    await until(() => received.length == 1);
  });
}
