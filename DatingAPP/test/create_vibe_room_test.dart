import 'package:dating_app/features/vibes/presentation/screens/create_vibe_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'creating a room returns to the previous screen and confirms it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateVibeRoomScreen(),
                    ),
                  ),
                  child: const Text('Vibes home'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Vibes home'));
      await tester.pumpAndSettle();
      expect(find.text('Create a vibe room'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Sunday Sketch Club',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create room'));
      await tester.pumpAndSettle();

      // Back on the screen that opened it, with a confirmation and a way in.
      expect(find.text('Create a vibe room'), findsNothing);
      expect(find.text('Vibes home'), findsOneWidget);
      expect(find.text('“Sunday Sketch Club” created ✨'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Open'), findsOneWidget);
    },
  );
}
