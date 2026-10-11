import 'package:dating_app/app/dating_app.dart';
import 'package:dating_app/core/constants/app_constants.dart';
import 'package:dating_app/features/welcome/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts directly on the welcome screen', (tester) async {
    await tester.pumpWidget(const DatingApp());
    await tester.pumpAndSettle();
    expect(find.text(AppConstants.name), findsOneWidget);
    expect(find.text(AppConstants.welcomeTitle), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome routes both actions through supplied callbacks', (
    tester,
  ) async {
    var started = false;
    var signedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          onGetStarted: () => started = true,
          onSignIn: () => signedIn = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    expect(started, isTrue);
    expect(signedIn, isFalse);
    await tester.tap(find.text('I already have an account'));
    expect(signedIn, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('welcome supports $size and large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const DatingApp(),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('I already have an account'),
        200,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
