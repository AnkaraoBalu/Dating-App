import 'dart:async';

import 'package:dating_app/features/login/presentation/screens/signed_in_gate.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/features/onboarding/data/onboarding_api.dart';
import 'package:dating_app/features/onboarding/models/onboarding_profile.dart';
import 'package:dating_app/features/login/presentation/screens/location_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _QueuedAccountApi extends OnboardingApi {
  _QueuedAccountApi()
    : super(
        baseUrl: 'https://example.test/api/v1',
        getSessionToken: () async => 'test',
      );
  final calls = <Completer<OnboardingProfile?>>[];
  @override
  Future<OnboardingProfile?> loadProfile() {
    final call = Completer<OnboardingProfile?>();
    calls.add(call);
    return call.future;
  }
}

void main() {
  testWidgets('overall startup timeout rejects late responses after retry', (
    tester,
  ) async {
    dotenv.testLoad(fileInput: 'API_URL=https://example.test/api/v1');
    final api = _QueuedAccountApi();
    await tester.pumpWidget(
      MaterialApp(home: SignedInGate(onboardingApi: api)),
    );
    await tester.pump(const Duration(seconds: 90));
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(api.calls.length, 2);
    api.calls.first.complete(OnboardingProfile(completedAt: DateTime(2026)));
    await tester.pump();
    expect(find.text('Loading your account...'), findsOneWidget);
    api.calls.last.complete(null);
    await tester.pump();
    expect(find.byType(LocationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

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
