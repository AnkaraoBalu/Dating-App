import 'package:dating_app/features/home/data/discovery_feed.dart';
import 'package:dating_app/features/home/data/home_discover_data.dart';
import 'package:flutter_test/flutter_test.dart';

HomePerson person(String id) => HomePerson(
  id: id,
  name: id,
  age: 25,
  image: '',
  distance: '',
  match: 0,
  bio: '',
  tags: const [],
);

void main() {
  test('failed swipe restores its position while retaining newer cards', () {
    final failed = person('b');
    final restored = restoreDiscoveryCard(
      [person('a'), person('c'), person('d')],
      failed,
      1,
    );
    expect(restored.map((card) => card.id), ['a', 'b', 'c', 'd']);
    expect(identical(restored[1], failed), isTrue);
    expect(restoreDiscoveryCard(restored, failed, 1).length, 4);
  });

  test('failed swipe restoration handles a changed or empty queue', () {
    expect(restoreDiscoveryCard([], person('a'), 10).single.id, 'a');
    expect(restoreDiscoveryCard([person('b')], person('a'), -1).first.id, 'a');
  });

  test('distance expansion advances without shrinking custom distances', () {
    expect(nextDiscoveryRadius(10), 25);
    expect(nextDiscoveryRadius(25), 50);
    expect(nextDiscoveryRadius(40), 50);
    expect(nextDiscoveryRadius(50), 100);
    expect(nextDiscoveryRadius(75), 100);
    expect(nextDiscoveryRadius(100), isNull);
  });

  test('refill keeps queued cards in order and adds each new profile once', () {
    final current = [person('a'), person('b')];
    final result = mergeDiscoveryFeed(
      current: current,
      incoming: [person('b'), person('c'), person('c'), person('d')],
      dismissedIds: {},
    );
    expect(result.map((p) => p.id), ['a', 'b', 'c', 'd']);
    expect(identical(result.first, current.first), isTrue);
  });

  test('swipes completed during refill cannot bring dismissed cards back', () {
    final result = mergeDiscoveryFeed(
      current: [person('a'), person('b')],
      incoming: [person('a'), person('c')],
      dismissedIds: {'a', 'c'},
    );
    expect(result.map((p) => p.id), ['b']);
  });

  test('an exhausted response preserves remaining queued cards', () {
    final result = mergeDiscoveryFeed(
      current: [person('a')],
      incoming: [],
      dismissedIds: {},
    );
    expect(result.map((p) => p.id), ['a']);
  });
}
