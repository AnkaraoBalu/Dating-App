import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/dating_app.dart';
import 'core/network/server_warmup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // The free API host sleeps when idle; start waking it now, and again
  // whenever the app returns to the foreground.
  unawaited(ServerWarmup.ping());
  AppLifecycleListener(onResume: () => unawaited(ServerWarmup.ping()));
  try {
    // Reads android/app/google-services.json or ios/Runner/GoogleService-Info.plist.
    await Firebase.initializeApp();
  } catch (error) {
    // Without Firebase config the app still runs, just without push notifications.
    debugPrint('[Push] Firebase is not configured: $error');
  }
  final publishableKey =
      (dotenv.env['CLERK_PUBLISHABLE_KEY']?.trim().isNotEmpty == true
              ? dotenv.env['CLERK_PUBLISHABLE_KEY']!
              : dotenv.env['VITE_CLERK_PUBLISHABLE_KEY'] ?? '')
          .trim();
  runApp(DatingApp(clerkPublishableKey: publishableKey));
}
