import 'package:dating_app/features/home/data/home_discover_data.dart';
import 'package:dating_app/features/home/presentation/screens/discover_filters_screen.dart';
import 'package:dating_app/features/profile/models/member_profile.dart';
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
    await tester.ensureVisible(find.text('Show results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();
    expect(result!.nearbyOnly, isTrue);
    final restored = result!.withProfilePreferences(
      radiusKm: 40,
      nearbyOnly: false,
      gender: 'woman',
    );
    expect(restored.nearbyOnly, isFalse);
    expect(restored.radiusKm, 40);
    expect(restored.gender, 'woman');
  });

  test('Show me follows the onboarding "interested in" answer', () {
    MemberProfile profile(String? interestedIn) => MemberProfile({
      'user': {
        'onboardingProfile': {'interestedIn': ?interestedIn},
      },
    });
    expect(profile('women').discoveryGender, 'woman');
    expect(profile('men').discoveryGender, 'man');
    expect(profile('everyone').discoveryGender, 'everyone');
    expect(profile(null).discoveryGender, 'everyone');
    for (final gender in ['woman', 'man', 'everyone']) {
      expect(
        profile(MemberProfile.interestedInFor(gender)).discoveryGender,
        gender,
      );
    }
  });

  testWidgets('Filters starts on the saved Show me choice', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscoverFiltersScreen(
          initial: DiscoverFilterOptions(gender: 'woman'),
        ),
      ),
    );
    ChoiceChip chip(String label) =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
    expect(chip('Women').selected, isTrue);
    expect(chip('Men').selected, isFalse);
    expect(chip('Everyone').selected, isFalse);
  });
}
