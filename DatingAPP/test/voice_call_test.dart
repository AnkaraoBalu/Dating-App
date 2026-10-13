import 'package:dating_app/features/calls/models/voice_call.dart';
import 'package:dating_app/features/chat/models/chat_models.dart';
import 'package:dating_app/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:dating_app/features/home/data/home_discover_data.dart';
import 'package:dating_app/features/notifications/models/push_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a started call with its audio join details', () {
    final call = VoiceCall.fromJson({
      'id': 'c1',
      'conversationId': 'conv',
      'status': 'ringing',
      'isCaller': false,
      'peer': {'id': 'arav', 'name': 'Arav', 'avatar': 'https://x/a.jpg'},
      'serverUrl': 'wss://voice.example',
      'participantToken': 'token',
    });
    expect(call.isRinging, isTrue);
    expect(call.isFinished, isFalse);
    expect(call.isCaller, isFalse);
    expect(call.peerName, 'Arav');
    expect(call.participantToken, 'token');
    expect(
      VoiceCall.fromJson({
        ...{'id': 'c1', 'status': 'missed', 'peer': <String, dynamic>{}},
      }).isFinished,
      isTrue,
    );
  });

  test('a call push carries the call to show', () {
    final push = PushNotification.fromData({
      'type': 'call',
      'callId': 'c1',
      'conversationId': 'conv',
    });
    expect(push.type, PushNotificationType.call);
    expect(push.callId, 'c1');
    expect(push.conversationId, 'conv');
  });

  testWidgets('calls appear in the chat as call lines', (tester) async {
    Future<void> show(ChatMessage message) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: message,
            person: const HomePerson(
              name: 'Zoya',
              age: 24,
              image: '',
              distance: '',
              match: 0,
              bio: '',
              tags: [],
            ),
            onRetry: () {},
          ),
        ),
      ),
    );

    await show(
      ChatMessage(
        id: 'm1',
        text: 'completed',
        type: 'call',
        durationMs: 151000,
        fromMe: true,
        sentAt: DateTime(2026),
      ),
    );
    expect(find.text('Voice call · 2:31'), findsOneWidget);
    expect(find.text('completed'), findsNothing);

    await show(
      ChatMessage(
        id: 'm2',
        text: 'missed',
        type: 'call',
        sentAt: DateTime(2026),
      ),
    );
    expect(find.text('Missed voice call'), findsOneWidget);
  });
}
