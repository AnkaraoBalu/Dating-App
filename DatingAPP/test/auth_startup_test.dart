import 'dart:async';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:dating_app/app/auth_startup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReadyAuth extends ChangeNotifier implements ClerkAuthState {
  _ReadyAuth(this.config) : telemetry = clerk.Telemetry(config: config);
  @override
  final ClerkAuthConfig config;
  @override
  final clerk.Telemetry telemetry;
  @override
  clerk.Client get client => clerk.Client.empty;
  @override
  clerk.Environment get env => clerk.Environment.empty;
  bool terminated = false;
  @override
  void terminate() {
    terminated = true;
    dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'successful authentication renders the app and disposes owned state',
    (tester) async {
      late _ReadyAuth auth;
      await tester.pumpWidget(
        AuthStartup(
          createConfig: () => ClerkAuthConfig(
            publishableKey: 'pk_test_ZXhhbXBsZS5jb20k',
            telemetryPeriod: Duration.zero,
          ),
          createAuth: (config) async => auth = _ReadyAuth(config),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('App ready'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('App ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        identical(ClerkAuth.of(tester.element(find.text('App ready'))), auth),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      expect(auth.terminated, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authentication timeout shows retry instead of an indefinite spinner',
    (tester) async {
      var attempts = 0;
      final configs = <ClerkAuthConfig>[];
      await tester.pumpWidget(
        AuthStartup(
          createConfig: () =>
              ClerkAuthConfig(publishableKey: 'pk_test_ZXhhbXBsZS5jb20k'),
          createAuth: (config) {
            configs.add(config);
            attempts++;
            return Completer<ClerkAuthState>().future;
          },
          child: const SizedBox(),
        ),
      );
      expect(find.text('Restoring your session...'), findsOneWidget);
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(attempts, 2);
      expect(identical(configs[0], configs[1]), isFalse);
      expect(find.text('Restoring your session...'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('authentication initialization errors show a retry screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      AuthStartup(
        createConfig: () =>
            ClerkAuthConfig(publishableKey: 'pk_test_ZXhhbXBsZS5jb20k'),
        createAuth: (_) async => throw StateError('Initialization failed'),
        child: const SizedBox(),
      ),
    );
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
