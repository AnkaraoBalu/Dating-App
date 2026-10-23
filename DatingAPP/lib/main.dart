import 'dart:async';

import 'core/startup/firebase_startup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/dating_app.dart';
import 'core/network/server_warmup.dart';

Future<void> main() async {
  final watch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // The free API host sleeps when idle; start waking it now, and again
  // whenever the app returns to the foreground.
  unawaited(ServerWarmup.ping());
  AppLifecycleListener(onResume: () => unawaited(ServerWarmup.ping()));
  unawaited(FirebaseStartup.initialize());
  final publishableKey =
      (dotenv.env['CLERK_PUBLISHABLE_KEY']?.trim().isNotEmpty == true
              ? dotenv.env['CLERK_PUBLISHABLE_KEY']!
              : dotenv.env['VITE_CLERK_PUBLISHABLE_KEY'] ?? '')
          .trim();
  runApp(DatingApp(clerkPublishableKey: publishableKey));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint(
      '[Startup] First frame in ${watch.elapsedMilliseconds}ms after startup',
    );
  });
}
