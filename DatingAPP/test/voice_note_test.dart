import 'package:dating_app/core/widgets/voice_note/voice_note_composer.dart';
import 'package:dating_app/features/vibes/models/vibe_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the composer shows a mic until there is text to send', (
    tester,
  ) async {
    final controller = TextEditingController();
    var sentText = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceNoteComposer(
            textController: controller,
            onSendText: () => sentText++,
            onSendVoice: (_) {},
            builder: (context, action) => Row(
              children: [
                Expanded(child: TextField(controller: controller)),
                action,
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    await tester.enterText(find.byType(TextField), 'Hi there');
    await tester.pump();
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
    await tester.tap(find.byIcon(Icons.send_rounded));
    expect(sentText, 1);
  });

  test('voice durations and chat previews read naturally', () {
    expect(formatVoiceDuration(const Duration(seconds: 7)), '0:07');
    expect(
      formatVoiceDuration(const Duration(minutes: 1, seconds: 42)),
      '1:42',
    );
    const voice = VibeRoomChatMessage(
      text: '',
      sender: 'Zoya',
      isMe: false,
      kind: 'voice',
    );
    expect(voice.preview, 'Zoya: 🎤 Voice message');
  });
}
