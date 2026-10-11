import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/dating_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final publishableKey =
      (dotenv.env['CLERK_PUBLISHABLE_KEY']?.trim().isNotEmpty == true
              ? dotenv.env['CLERK_PUBLISHABLE_KEY']!
              : dotenv.env['VITE_CLERK_PUBLISHABLE_KEY'] ?? '')
          .trim();
  runApp(DatingApp(clerkPublishableKey: publishableKey));
}
