import 'dart:convert';

import 'package:dating_app/features/notifications/data/notifications_api.dart';
import 'package:dating_app/features/notifications/models/push_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/features/notifications/presentation/widgets/in_app_notification.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('foreground banner appears at the top and opens on tap', (
    tester,
  ) async {
    final banner = InAppNotification();
    late BuildContext context;
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    banner.show(
      context,
      notification: const PushNotification(
        type: PushNotificationType.message,
        title: 'New message',
        body: 'Hello',
      ),
      onTap: () => tapped = true,
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('New message')).dy, lessThan(100));
    await tester.tap(find.text('New message'));
    await tester.pump();
    expect(tapped, isTrue);
    expect(find.text('New message'), findsNothing);
    banner.show(
      context,
      notification: const PushNotification(
        type: PushNotificationType.like,
        title: 'New like',
      ),
      onTap: () {},
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('New like'), findsNothing);
  });

  test('reads each notification type from the push data', () {
    final message = PushNotification.fromData(
      {'type': 'message', 'conversationId': 'c1'},
      title: 'Aarav',
      body: 'See you at 7?',
    );
    expect(message.type, PushNotificationType.message);
    expect(message.conversationId, 'c1');
    expect(message.title, 'Aarav');
    expect(message.body, 'See you at 7?');

    final match = PushNotification.fromData({'type': 'match', 'userId': 'u2'});
    expect(match.type, PushNotificationType.match);
    expect(match.userId, 'u2');

    expect(
      PushNotification.fromData({'type': 'like'}).type,
      PushNotificationType.like,
    );
    expect(
      PushNotification.fromData({'type': 'something-new'}).type,
      PushNotificationType.unknown,
    );
  });

  test('registers and removes this phone with the signed-in token', () async {
    final requests = <http.Request>[];
    final api = NotificationsApi(
      baseUrl: 'https://api.test/api/v1',
      getSessionToken: () async => 'session-token',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 201);
      }),
    );
    await api.registerDevice(token: 'fcm-token', platform: 'android');
    await api.removeDevice('fcm-token');

    expect(requests[0].method, 'POST');
    expect(
      requests[0].url.toString(),
      'https://api.test/api/v1/notifications/devices',
    );
    expect(requests[0].headers['Authorization'], 'Bearer session-token');
    expect(jsonDecode(requests[0].body), {
      'token': 'fcm-token',
      'platform': 'android',
    });
    expect(requests[1].method, 'DELETE');
    expect(jsonDecode(requests[1].body), {'token': 'fcm-token'});
  });

  test('a rejected registration reports the server message', () async {
    final api = NotificationsApi(
      baseUrl: 'https://api.test/api/v1',
      getSessionToken: () async => 'session-token',
      client: MockClient(
        (_) async => http.Response('{"message":"Invalid token"}', 400),
      ),
    );
    expect(
      api.registerDevice(token: 'x', platform: 'ios'),
      throwsA(predicate((e) => '$e'.contains('Invalid token'))),
    );
  });
}
