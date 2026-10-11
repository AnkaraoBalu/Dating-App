import 'dart:convert';
import 'dart:io';

import 'package:dating_app/features/chat/data/chat_api.dart';
import 'package:dating_app/features/chat/data/chat_controller.dart';
import 'package:dating_app/features/chat/data/chat_socket_service.dart';
import 'package:dating_app/features/chat/models/chat_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<void> until(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for chat state');
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
    'slow socket authentication does not hold the history loading spinner',
    () async {
      final baseUrl = await startFixture();
      final api = ChatApi(
        baseUrl: baseUrl,
        getSessionToken: () async => 'arav:slow',
      );
      final controller = ChatController(
        api: api,
        socket: ChatSocketService(api),
      );
      addTearDown(controller.dispose);
      await controller.open('zoya', existingConversationId: 'conversation');
      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.socket.ready, isFalse);
      await until(() => controller.socket.ready);
    },
  );

  test(
    'a rate-limited send fails with the reason and can be retried',
    () async {
      final baseUrl = await startFixture();
      final api = ChatApi(
        baseUrl: baseUrl,
        getSessionToken: () async => 'arav:1',
      );
      final controller = ChatController(
        api: api,
        socket: ChatSocketService(api),
      );
      addTearDown(controller.dispose);
      final reasons = <String>[];
      controller.sendErrors.listen(reasons.add);
      await controller.open('zoya', existingConversationId: 'conversation');
      await until(() => controller.socket.ready);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller.sendText('__rate_limited__'), isTrue);
      await until(() => reasons.isNotEmpty);
      expect(
        reasons.single,
        "You're sending messages too fast. Try again in 3 seconds.",
      );
      final failed = controller.messages.single;
      expect(failed.failed, isTrue);
      expect(failed.pending, isFalse);
    },
  );

  test(
    'messages sent during initial history loading are recovered after joining',
    () async {
      final baseUrl = await startFixture();
      ChatController chat(String user) {
        final api = ChatApi(
          baseUrl: baseUrl,
          getSessionToken: () async => user,
        );
        return ChatController(api: api, socket: ChatSocketService(api));
      }

      final zoya = chat('zoya');
      final arav = chat('arav');
      addTearDown(zoya.dispose);
      addTearDown(arav.dispose);
      await zoya.open('arav', existingConversationId: 'conversation');
      await until(() => zoya.socket.ready);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await http.get(Uri.parse('$baseUrl/fixture/delay-history'));
      final opening = arav.open('zoya', existingConversationId: 'conversation');
      await until(() => arav.socket.ready);
      expect(arav.loading, isTrue);
      zoya.sendText('During loading');
      await opening;
      await until(() => arav.messages.length == 1);
      expect(arav.messages.single.text, 'During loading');
      expect(arav.messages.single.fromMe, isFalse);
      expect(arav.loading, isFalse);
    },
  );

  test(
    'sender mapping uses authenticated viewer consistently for both accounts',
    () {
      final row = {
        'id': 'reply',
        'senderId': 'arav',
        'fromMe': false,
        'text': 'Reply',
      };
      expect(
        ChatMessage.fromJson(
          row,
          peerUserId: 'zoya',
          currentUserId: 'arav',
        ).fromMe,
        isTrue,
      );
      expect(
        ChatMessage.fromJson(
          row,
          peerUserId: 'arav',
          currentUserId: 'zoya',
        ).fromMe,
        isFalse,
      );
      expect(
        ChatMessage.fromJson(
          {...row, 'fromMe': true},
          peerUserId: 'arav',
          currentUserId: 'zoya',
        ).fromMe,
        isFalse,
      );
    },
  );

  test(
    'REST history includes the viewer identity and keeps replies on reopening',
    () async {
      final api = ChatApi(
        baseUrl: 'http://fixture',
        getSessionToken: () async => 'arav',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'viewerId': 'arav',
              'items': [
                {'id': '1', 'senderId': 'zoya', 'text': 'Hi'},
                {'id': '2', 'senderId': 'arav', 'text': 'Reply'},
              ],
              'hasMore': false,
            }),
            200,
          ),
        ),
      );
      addTearDown(api.close);
      for (var reopen = 0; reopen < 2; reopen++) {
        final page = await api.loadMessages(
          conversationId: 'conversation',
          peerUserId: 'zoya',
        );
        expect(page.items.map((m) => m.fromMe), [false, true]);
      }
    },
  );

  test(
    'real sockets isolate accounts, preserve replies after reopening, and refresh auth on reconnect',
    () async {
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
      final baseUrl = 'http://127.0.0.1:$port';
      var revision = 1;
      ChatController chat(String user) {
        final api = ChatApi(
          baseUrl: baseUrl,
          getSessionToken: () async => '$user:$revision',
        );
        return ChatController(api: api, socket: ChatSocketService(api));
      }

      final zoya = chat('zoya');
      var arav = chat('arav');
      addTearDown(zoya.dispose);
      addTearDown(() => arav.dispose());
      await Future.wait([
        zoya.open('arav', existingConversationId: 'conversation'),
        arav.open('zoya', existingConversationId: 'conversation'),
      ]);
      await until(() => zoya.socket.ready && arav.socket.ready);
      // Allow conversation:joined events to arrive before the first send.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(zoya.socket.currentUserId, 'zoya');
      expect(arav.socket.currentUserId, 'arav');
      expect(zoya.sendText('Hello Arav'), isTrue);
      await until(
        () => arav.messages.length == 1 && !zoya.messages.single.pending,
      );
      expect(zoya.messages.single.fromMe, isTrue);
      expect(arav.messages.single.fromMe, isFalse);
      expect(arav.sendText('Hello Zoya'), isTrue);
      await until(
        () => zoya.messages.length == 2 && !arav.messages.last.pending,
      );
      expect(arav.messages.last.fromMe, isTrue);
      expect(zoya.messages.last.fromMe, isFalse);
      expect(arav.messages.length, 2);
      // Returning to a chat discards optimistic state and reloads saved history.
      arav.dispose();
      arav = chat('arav');
      await arav.open('zoya', existingConversationId: 'conversation');
      await until(() => arav.socket.ready && arav.messages.length == 2);
      expect(arav.messages.map((m) => m.fromMe), [false, true]);
      revision = 2;
      await http.get(Uri.parse('$baseUrl/fixture/drop'));
      await until(() => !zoya.socket.ready);
      await until(() => zoya.socket.ready && arav.socket.ready);
      final state =
          jsonDecode((await http.get(Uri.parse('$baseUrl/fixture/state'))).body)
              as Map;
      expect(state['authTokens'], contains('zoya:2'));
      expect(state['authTokens'], contains('arav:2'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      arav.sendText('After reconnect');
      await until(
        () => zoya.messages.length == 3 && !arav.messages.last.pending,
      );
      expect(zoya.messages.last.fromMe, isFalse);
      expect(arav.messages.last.fromMe, isTrue);
      expect(arav.messages.last.id.startsWith('local-'), isFalse);
      // A user's own read event must not mark their own sends as Seen.
      await http.get(
        Uri.parse('$baseUrl/fixture/receipt?reader=zoya&last=message-3'),
      );
      await until(() => arav.messages.last.readAt != null);
      expect(zoya.messages.first.readAt, isNull);
      await arav.retryConnection();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(arav.messages.last.readAt, isNotNull);
      // Recover an offline gap larger than the 50-message history page.
      await http.get(Uri.parse('$baseUrl/fixture/drop?user=arav'));
      await until(() => !arav.socket.ready);
      for (var index = 0; index < 65; index++) {
        zoya.sendText('Offline message $index');
      }
      await until(
        () =>
            zoya.messages.length == 68 &&
            zoya.messages.every((m) => !m.pending),
      );
      await until(() => arav.socket.ready && arav.messages.length == 68);
      expect(arav.messages.map((m) => m.id).toSet().length, 68);
      expect(arav.messages.where((m) => m.fromMe).length, 2);
    },
  );
}
