import 'package:dating_app/app/dating_app.dart';
import 'package:dating_app/core/theme/theme.dart';
import 'package:dating_app/features/login/data/preview_login_service.dart';
import 'package:dating_app/features/login/models/verification_challenge.dart';
import 'package:dating_app/features/login/presentation/screens/login_screen.dart';
import 'package:dating_app/features/login/presentation/screens/email_login_screen.dart';
import 'package:dating_app/features/login/presentation/screens/phone_login_screen.dart';
import 'package:dating_app/features/login/presentation/screens/verify_phone_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one Google button signs in or creates the account', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Just2'), findsOneWidget);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.text('Create account'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('missing Clerk configuration disables real login safely', (
    tester,
  ) async {
    await tester.pumpWidget(const DatingApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('Sign-in is unavailable.'), findsOneWidget);
    expect(find.text('Continue with Phone'), findsNothing);
    expect(find.textContaining('preview code'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'code validates length, rejects wrong code, accepts preview code',
    (tester) async {
      var verified = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: VerifyPhoneScreen(
            challenge: const VerificationChallenge(
              phoneNumber: '+919876543210',
              previewCode: PreviewLoginService.code,
            ),
            onVerified: () => verified++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify code'));
      await tester.pump();
      expect(find.text('Enter all 6 digits.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('verification-code')),
        '654321',
      );
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(verified, 0);
      expect(
        find.text('That code does not match. Try the preview code below.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('verification-code')),
        '123456',
      );
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();
      expect(verified, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('resend unlocks after countdown and resets the code', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 7);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: VerifyPhoneScreen(
          challenge: const VerificationChallenge(
            phoneNumber: '+919876543210',
            previewCode: PreviewLoginService.code,
          ),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resend code in 00:30'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('verification-code')),
      '123',
    );
    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    expect(find.text('Resend code in 00:30'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('verification-code')),
          )
          .controller!
          .text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('login screens support $size with large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in [
        const LoginScreen(),
        const EmailLoginScreen(),
        const PhoneLoginScreen(),
        const VerifyPhoneScreen(
          challenge: VerificationChallenge(
            phoneNumber: '+919876543210',
            previewCode: '123456',
          ),
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: page,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
