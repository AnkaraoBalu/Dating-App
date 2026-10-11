import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;

/// Clerk Flutter may emit an error instead of throwing when a listener exists.
/// Capture errors for this attempt so the screen cannot treat failure as success.
Future<T> runClerkOperation<T>({
  required Stream<clerk.ClerkError> errors,
  required Future<T> Function() operation,
}) async {
  clerk.ClerkError? reportedError;
  final subscription = errors.listen((error) => reportedError ??= error);
  try {
    final result = await operation();
    // Allow errors emitted by an asynchronous broadcast stream to arrive.
    await Future<void>.value();
    if (reportedError != null) throw reportedError!;
    return result;
  } finally {
    await subscription.cancel();
  }
}
