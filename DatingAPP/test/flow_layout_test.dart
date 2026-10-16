import 'package:dating_app/core/widgets/adaptive_flow_column.dart';
import 'package:dating_app/core/theme/theme.dart';
import 'package:dating_app/features/onboarding/data/onboarding_api.dart';
import 'package:dating_app/features/onboarding/data/onboarding_question_copy.dart';
import 'package:dating_app/features/onboarding/models/onboarding_profile.dart';
import 'package:dating_app/features/onboarding/presentation/screens/onboarding_questions_screen.dart';
import 'package:dating_app/features/profile_setup/data/profile_setup_api.dart';
import 'package:dating_app/features/profile_setup/data/profile_setup_options.dart';
import 'package:dating_app/features/profile_setup/data/profile_setup_copy.dart';
import 'package:dating_app/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:dating_app/features/home/presentation/screens/home_screen.dart';
import 'package:dating_app/features/home/presentation/screens/discover_filters_screen.dart';
import 'package:dating_app/features/home/presentation/screens/discover_categories_screen.dart';
import 'package:dating_app/features/home/presentation/screens/discover_travel_screen.dart';
import 'package:dating_app/features/home/presentation/screens/profile_quick_preview_screen.dart';
import 'package:dating_app/features/home/presentation/screens/profile_detail_screen.dart';
import 'package:dating_app/features/home/data/home_discover_data.dart';
import 'package:dating_app/features/home/presentation/widgets/home_discover_sections.dart';
import 'package:dating_app/features/profile_setup/presentation/screens/profile_basics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class LayoutOnboardingApi extends OnboardingApi {
  LayoutOnboardingApi()
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token');
  String? savedName;
  Map<String, Object?>? savedChanges;
  @override
  Future<void> update(Map<String, Object?> changes) async {
    savedChanges = changes;
  }

  @override
  Future<void> updateName(String name) async {
    savedName = name.trim();
  }
}

class LayoutProfileApi extends ProfileSetupApi {
  LayoutProfileApi({this.full = false})
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token');
  final bool full;
  @override
  Future<Map<String, dynamic>> load() async => {
    'photos': full
        ? [
            for (var i = 0; i < 4; i++)
              {'id': '$i', 'secureUrl': 'https://example.test/$i.png'},
          ]
        : <dynamic>[],
    'prompts': full
        ? [
            for (final question
                in ProfileSetupOptions.promptSections.values.first.take(3))
              {'question': question, 'answer': 'Coffee and good conversations'},
          ]
        : <dynamic>[],
    'user': <String, dynamic>{'firstName': 'Vinod'},
  };
  @override
  Future<Map<String, dynamic>> update(Map<String, Object?> changes) => load();
  @override
  Future<Map<String, dynamic>> savePrompts(List<Map<String, String>> prompts) =>
      load();
}

OnboardingProfile answersBefore(int step) => OnboardingProfile(
  username: 'Vinod',
  birthDate: step > 0 ? DateTime(2000, 1, 1) : null,
  genderIdentity: step > 1 ? 'man' : null,
  interestedIn: step > 2 ? 'women' : null,
  vibeTypes: step > 4 ? ['sunshine'] : const [],
  idealFridays: step > 5 ? ['quiet_evening'] : const [],
  interests: step > 6 ? ['coffee'] : [],
  musicGenres: step > 7 ? ['pop'] : [],
  currentEras: step > 8 ? ['career_mode'] : const [],
  dealbreakers: step > 9 ? ['honesty'] : [],
  datingIntentions: step > 10 ? ['something_serious'] : [],
  skippedQuestions: step > 11 ? ['location_preferences'] : [],
);
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('birthday step requires and saves the entered name', (
    tester,
  ) async {
    final api = LayoutOnboardingApi();
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingQuestionsScreen(api: api, initialProfile: null),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-name')),
      '  Aanya  ',
    );
    await tester.pump();
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FloatingActionButton));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(api.savedName, 'Aanya');
    expect(api.savedChanges?['birthDate'], isNotNull);
    expect(find.text('Your gender identity'), findsOneWidget);
  });
  testWidgets('keyboard resizing preserves answer focus and text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowColumn(
            children: [
              const SizedBox(height: 100),
              Expanded(child: TextFormField()),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'My answer');
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    final after = tester.state<EditableTextState>(find.byType(EditableText));
    expect(identical(before, after), isTrue);
    expect(after.widget.focusNode.hasFocus, isTrue);
    expect(after.widget.controller.text, 'My answer');
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('onboarding and setup fit $size with larger text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> show(Widget screen) async {
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details, forceReport: true);
          previous?.call(details);
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: screen,
          ),
        );
        await tester.pumpAndSettle();
        FlutterError.onError = previous;
      }

      for (final step in [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
        await show(
          OnboardingQuestionsScreen(
            key: ValueKey(step),
            api: LayoutOnboardingApi(),
            initialProfile: answersBefore(step),
          ),
        );
        expect(find.text(OnboardingQuestionCopy.titles[step]), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Onboarding step $step at $size',
        );
      }
      await show(
        OnboardingQuestionsScreen(
          key: const ValueKey('intro'),
          api: LayoutOnboardingApi(),
          initialProfile: answersBefore(2),
        ),
      );
      await tester.ensureVisible(find.text('Women'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Women'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text(OnboardingQuestionCopy.titles[3]), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Onboarding intro at $size',
      );
      await show(ProfileSetupScreen(api: LayoutProfileApi()));
      expect(tester.takeException(), isNull, reason: 'Profile setup at $size');
      await show(
        ProfileSetupScreen(
          key: const ValueKey('full-profile'),
          api: LayoutProfileApi(full: true),
        ),
      );
      for (var step = 0; step <= 8; step++) {
        expect(find.text(ProfileSetupCopy.titles[step]), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Profile setup step $step at $size',
        );
        final next = find.byKey(const ValueKey('profile-setup-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.byType(ProfileBasicsScreen), findsOneWidget);
      for (var step = 1; step <= 10; step++) {
        expect(
          tester.takeException(),
          isNull,
          reason: 'Profile basics step $step at $size',
        );
        final next = find.byKey(const ValueKey('profile-basics-next'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      // The Spotify step (9) is skipped; basics lead to the profile preview.
      expect(find.text(ProfileSetupCopy.titles[9]), findsNothing);
      expect(find.text(ProfileSetupCopy.titles[10]), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Profile preview at $size',
      );
      await show(const HomeScreen(displayName: 'Vinod'));
      expect(tester.takeException(), isNull, reason: 'Discover at $size');
      await show(const DiscoverFiltersScreen());
      expect(
        tester.takeException(),
        isNull,
        reason: 'Discover filters at $size',
      );
      for (final screen in [
        const DiscoverCategoriesScreen(),
        const DiscoverTravelScreen(),
        const ProfileQuickPreviewScreen(person: HomeDiscoverData.lead),
        const ProfileDetailScreen(person: HomeDiscoverData.lead),
        ProfileBasicsScreen(api: LayoutProfileApi(), initialValues: const {}),
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: HomeDiscoverSections.leadCard(
              person: HomeDiscoverData.lead,
              onMore: () {},
              onPass: () {},
              onLike: () {},
              onTap: () {},
              liked: false,
            ),
          ),
        ),
      ]) {
        await show(screen);
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} at $size',
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
