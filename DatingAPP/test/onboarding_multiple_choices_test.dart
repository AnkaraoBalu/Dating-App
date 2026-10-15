import 'package:dating_app/features/onboarding/data/onboarding_api.dart';
import 'package:dating_app/features/onboarding/models/onboarding_profile.dart';
import 'package:dating_app/features/onboarding/presentation/screens/onboarding_questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ChoiceApi extends OnboardingApi {
  ChoiceApi()
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token');
  Map<String, Object?>? saved;
  @override
  Future<void> update(Map<String, Object?> changes) async {
    saved = changes;
  }
}

void main() {
  test('legacy answers are restored and explicit empty lists stay cleared', () {
    final old = OnboardingProfile.fromJson({
      'vibeType': 'sunshine',
      'idealFriday': 'gaming',
      'currentEra': 'career_mode',
    });
    expect(old.vibeTypes, ['sunshine']);
    expect(old.idealFridays, ['gaming']);
    expect(old.currentEras, ['career_mode']);
    final cleared = OnboardingProfile.fromJson({
      'vibeType': 'sunshine',
      'vibeTypes': <String>[],
    });
    expect(cleared.vibeTypes, isEmpty);
    expect(
      OnboardingProfile.fromJson({
        'idealFridays': ['gaming', 'club'],
      }).idealFridays,
      ['gaming', 'club'],
    );
  });

  for (final scenario in [
    (
      4,
      'vibeTypes',
      ['Golden retriever', 'Black cat', 'Social butterfly', 'Chill & balanced'],
      [
        'golden_retriever',
        'black_cat',
        'social_butterfly',
        'chill_and_balanced',
      ],
      3,
    ),
    (
      5,
      'idealFridays',
      [
        'Out dancing',
        'Movie + good food',
        'A late-night drive',
        'Gaming night',
      ],
      ['club', 'movie_and_food', 'long_drive', 'gaming'],
      3,
    ),
    (
      8,
      'currentEras',
      ['Rebuilding era', 'Career mode', 'Travel era'],
      ['rebuilding', 'career_mode', 'travel_era'],
      2,
    ),
  ]) {
    testWidgets(
      '${scenario.$2} supports multiple choices, enforces cap, and allows deselection',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ChoiceApi();
        await tester.pumpWidget(
          MaterialApp(
            home: OnboardingQuestionsScreen(
              api: api,
              initialProfile: OnboardingProfile(
                username: 'Member',
                birthDate: DateTime(2000),
                genderIdentity: 'man',
                interestedIn: 'women',
                vibeTypes: scenario.$1 > 4 ? ['sunshine'] : [],
                idealFridays: scenario.$1 > 5 ? ['gaming'] : [],
                interests: ['coffee'],
                musicGenres: ['indie'],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in scenario.$3) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pump();
        }
        // Deselecting at the cap must remain possible, then reselect it.
        await tester.scrollUntilVisible(
          find.text(scenario.$3.first),
          -150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text(scenario.$3.first));
        await tester.pump();
        await tester.tap(find.text(scenario.$3.first));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(api.saved![scenario.$2], [
          ...scenario.$4.take(scenario.$5).skip(1),
          scenario.$4.first,
        ]);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
