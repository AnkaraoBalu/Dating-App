import 'package:dating_app/features/chat/models/chat_models.dart';
import 'package:dating_app/features/chat/presentation/screens/shared_items_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 23, 12);
  final messages = [
    ChatMessage(
      id: '1',
      text: 'Menu is at https://cafe.example/menu, and www.example.org too.',
      sentAt: now.subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      id: '2',
      text: 'Here I am',
      type: 'location',
      latitude: 17.385,
      longitude: 78.4867,
      sentAt: now.subtract(const Duration(hours: 1)),
      fromMe: true,
    ),
    ChatMessage(id: '3', text: 'no links here', sentAt: now),
  ];

  test('finds links in text and trims trailing punctuation', () {
    final links = sharedItems(messages, SharedItemKind.links);
    expect(links.map((l) => l.title), [
      'https://cafe.example/menu',
      'www.example.org',
    ]);
    expect(links.last.uri.toString(), 'https://www.example.org');
  });

  test('finds shared locations with a maps link', () {
    final locations = sharedItems(messages, SharedItemKind.locations);
    expect(locations, hasLength(1));
    expect(locations.single.title, '17.3850, 78.4867');
    expect(
      locations.single.uri.toString(),
      'https://maps.google.com/?q=17.385,78.4867',
    );
    expect(locations.single.message.fromMe, isTrue);
  });
}
