import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:dating_app/features/login/data/clerk_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Clerk operation returns successful result and removes its listener',
    () async {
      final errors = StreamController<clerk.ClerkError>.broadcast();
      final result = await runClerkOperation(
        errors: errors.stream,
        operation: () async => 'code sent',
      );
      expect(result, 'code sent');
      expect(errors.hasListener, isFalse);
      await errors.close();
    },
  );

  test(
    'streamed Clerk failure cannot be treated as a successful code send',
    () async {
      final errors = StreamController<clerk.ClerkError>.broadcast();
      final failure = clerk.ClerkError.external(
        Exception('Code send rejected'),
      );
      await expectLater(
        runClerkOperation(
          errors: errors.stream,
          operation: () async {
            errors.add(failure);
            return 'not success';
          },
        ),
        throwsA(same(failure)),
      );
      expect(errors.hasListener, isFalse);
      await errors.close();
    },
  );

  test('thrown network failure is preserved and listener is removed', () async {
    final errors = StreamController<clerk.ClerkError>.broadcast();
    final failure = Exception('Offline');
    await expectLater(
      runClerkOperation<void>(
        errors: errors.stream,
        operation: () async => throw failure,
      ),
      throwsA(same(failure)),
    );
    expect(errors.hasListener, isFalse);
    await errors.close();
  });

  test('a failed attempt does not contaminate the next attempt', () async {
    final errors = StreamController<clerk.ClerkError>.broadcast();
    await expectLater(
      runClerkOperation<void>(
        errors: errors.stream,
        operation: () async =>
            errors.add(clerk.ClerkError.external(Exception('Wrong code'))),
      ),
      throwsA(isA<clerk.ClerkError>()),
    );
    expect(
      await runClerkOperation(
        errors: errors.stream,
        operation: () async => true,
      ),
      isTrue,
    );
    await errors.close();
  });
}
