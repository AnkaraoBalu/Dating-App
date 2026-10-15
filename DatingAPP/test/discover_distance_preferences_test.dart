import 'package:dating_app/features/home/data/home_discover_data.dart';
import 'package:dating_app/features/home/presentation/screens/discover_filters_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('people outside the distance are labelled on their cards', () {
    HomePerson person({required bool beyond}) => HomePerson(
      name: 'Asha',
      age: 25,
      image: '',
      distance: '140 km away',
      match: 0,
      bio: '',
      tags: const [],
      beyondRadius: beyond,
    );
    expect(person(beyond: false).distanceLabel, '140 km away');
    expect(
      person(beyond: true).distanceLabel,
      '140 km away · outside your range',
    );
  });

  testWidgets('Filters returns the nearby-only choice', (tester) async {
    DiscoverFilterOptions? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.push(
              context,
              MaterialPageRoute<DiscoverFilterOptions>(
                builder: (_) => const DiscoverFiltersScreen(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('filters-nearby-only'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(
      find.text('People further away appear after those nearby.'),
      findsOneWidget,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('People further away are hidden.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Show results'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();
    expect(result!.nearbyOnly, isTrue);
    expect(result!.withDistance(40, false).nearbyOnly, isFalse);
    expect(result!.withDistance(40, false).radiusKm, 40);
  });
}
