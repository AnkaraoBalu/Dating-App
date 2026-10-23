import 'dart:async';

import 'package:dating_app/features/login/presentation/screens/signed_in_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a stalled session token exits loading and allows retry', (
    tester,
  ) async {
    dotenv.testLoad(fileInput: 'API_URL=https://example.test/api/v1');
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SignedInGate(
          sessionTokenProvider: () {
            attempts++;
            return Completer<String>().future;
          },
        ),
      ),
    );
    expect(find.text('Loading your account...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Could not load your account'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
