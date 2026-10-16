import 'dart:convert';

import 'package:dating_app/features/safety/data/safety_api.dart';
import 'package:dating_app/features/safety/presentation/safety_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;
  SafetyApi api({int status = 201}) => SafetyApi(
    baseUrl: 'https://api.test/api/v1',
    getSessionToken: () async => 'token',
    client: MockClient((request) async {
      requests.add(request);
      return http.Response(
        status < 300 ? '{}' : jsonEncode({'message': 'Member not found.'}),
        status,
      );
    }),
  );

  setUp(() => requests = []);

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return context;
  }

  testWidgets('report needs a reason and sends it with optional details', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    final result = showReportFlow(
      context,
      api: api(),
      userId: 'user-2',
      name: 'Priya',
      source: 'chat',
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const ValueKey('report-send'));
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('report-harassment')));
    await tester.enterText(
      find.byKey(const ValueKey('report-details')),
      '  Rude messages ',
    );
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(requests.single.url.path, '/api/v1/safety/users/user-2/report');
    expect(requests.single.headers['Authorization'], 'Bearer token');
    expect(jsonDecode(requests.single.body), {
      'reason': 'harassment',
      'details': 'Rude messages',
      'source': 'chat',
    });
    expect(find.textContaining('Priya is blocked'), findsOneWidget);
  });

  testWidgets('block asks first and only blocks after confirming', (
    tester,
  ) async {
    final context = await pumpHost(tester);
    var result = confirmAndBlock(
      context,
      api: api(),
      userId: 'user-2',
      name: 'Priya',
    );
    await tester.pumpAndSettle();
    expect(find.text('Block Priya?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(requests, isEmpty);

    result = confirmAndBlock(
      context,
      api: api(),
      userId: 'user-2',
      name: 'Priya',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('safety-confirm-Block')));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(requests.single.url.path, '/api/v1/safety/users/user-2/block');
    expect(find.text('Priya is blocked.'), findsOneWidget);
  });

  testWidgets('a failed unmatch shows the server message', (tester) async {
    final context = await pumpHost(tester);
    final result = confirmAndUnmatch(
      context,
      api: api(status: 404),
      userId: 'user-2',
      name: 'Priya',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('safety-confirm-Unmatch')));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(requests.single.url.path, '/api/v1/safety/users/user-2/unmatch');
    expect(find.text('Member not found.'), findsOneWidget);
  });
}
