import 'package:dating_app/features/chat/models/chat_models.dart';
import 'package:dating_app/features/chat/presentation/screens/chat_search_screen.dart';
import 'package:dating_app/features/matches/models/match_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final match = MatchDemoData.matches.first;
  final now = DateTime.now();
  final messages = [
    ChatMessage(
      id: '1',
      text: 'Want to grab coffee on Sunday?',
      sentAt: now.subtract(const Duration(minutes: 30)),
    ),
    ChatMessage(
      id: '2',
      text: 'Sunday works, see you at 5',
      sentAt: now.subtract(const Duration(minutes: 10)),
      fromMe: true,
    ),
    ChatMessage(
      id: '3',
      text: '',
      type: 'image',
      sentAt: now.subtract(const Duration(minutes: 5)),
    ),
  ];

  Future<void> open(WidgetTester tester, {bool older = false}) =>
      tester.pumpWidget(
        MaterialApp(
          home: ChatSearchScreen(
            match: match,
            messages: messages,
            olderMessagesAvailable: older,
          ),
        ),
      );

  testWidgets('searches the real conversation, newest first', (tester) async {
    await open(tester);
    expect(find.text('2 results'), findsOneWidget);
    expect(find.text('That sounds amazing! Tell me more ✨'), findsNothing);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump();
    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('Want to grab coffee on Sunday?'), findsOneWidget);
    expect(find.text(match.person.name), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sunday');
    await tester.pump();
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((d) => d != null && d.contains('Sunday'))
        .toList();
    expect(texts, [
      'Sunday works, see you at 5',
      'Want to grab coffee on Sunday?',
    ]);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('says when older messages are not loaded yet', (tester) async {
    await open(tester);
    expect(find.textContaining('Scroll up in the chat'), findsNothing);
    await open(tester, older: true);
    expect(find.textContaining('Scroll up in the chat'), findsOneWidget);
  });
}
