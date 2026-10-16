import 'package:dating_app/core/constants/legal_links.dart';
import 'package:dating_app/features/profile/data/profile_controller.dart';
import 'package:dating_app/features/onboarding/data/onboarding_api.dart';
import 'package:dating_app/features/profile/models/member_profile.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_basic_info_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_about_me_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_more_details_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_preview_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_education_work_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_interests_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_privacy_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_main_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_verification_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_insights_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_photo_gallery_screen.dart';
import 'package:dating_app/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture() => {
  'user': {
    'username': 'Vinod J',
    'firstName': 'Clerk name',
    'lastName': 'J',
    'onboardingProfile': {
      'birthDate': '2000-10-09',
      'genderIdentity': 'man',
      'interests': ['coffee', 'travel', 'music', 'art', 'books'],
    },
  },
  'location': 'Hyderabad',
  'bio': 'Coffee and long walks',
  'education': 'B.Tech',
  'languages': ['English', 'Telugu'],
  'photos': <dynamic>[],
  'prompts': <dynamic>[],
  'showProfile': true,
  'showDistance': true,
  'showOnlineStatus': true,
};

class DistanceOnboardingApi extends OnboardingApi {
  DistanceOnboardingApi()
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token');
  bool fail = false;
  @override
  Future<void> update(Map<String, Object?> changes) async {
    if (fail) throw Exception('Save failed');
  }
}

class FakeProfileController extends ProfileController {
  FakeProfileController()
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token') {
    profile = MemberProfile(fixture());
    insights = {'matches': 7, 'likesReceived': 12, 'likesSent': 9};
  }
  Map<String, Object?>? lastChanges;
  @override
  Future<void> update(Map<String, Object?> changes) async {
    lastChanges = changes;
    profile = MemberProfile({...profile!.data, ...changes});
    notifyListeners();
  }

  @override
  Future<void> updateOnboarding(Map<String, Object?> changes) async {
    lastChanges = changes;
    profile = MemberProfile({
      ...profile!.data,
      'user': {
        ...profile!.user,
        'onboardingProfile': {...profile!.onboarding, ...changes},
      },
    });
    notifyListeners();
  }

  @override
  Future<void> savePrompts(List<Map<String, String>> prompts) async {
    profile = MemberProfile({...profile!.data, 'prompts': prompts});
    notifyListeners();
  }
}

void main() {
  testWidgets('Settings links to support, guidelines, terms and privacy', (
    tester,
  ) async {
    final controller = FakeProfileController();
    await tester.pumpWidget(
      MaterialApp(home: ProfileSettingsScreen(controller: controller)),
    );
    for (final title in [
      'Help & support',
      'Community guidelines',
      'Terms of service',
      'Privacy policy',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(LegalLinks.privacy.toString(), 'https://just2.in/privacy');
    expect(LegalLinks.terms.toString(), 'https://just2.in/terms');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  test(
    'confirmed distance writes update listeners; failed writes preserve the saved value',
    () async {
      final api = DistanceOnboardingApi();
      final controller = ProfileController(
        baseUrl: 'http://unused',
        getSessionToken: () async => 'token',
        onboardingApi: api,
      )..profile = MemberProfile(fixture());
      final observed = <int>[];
      controller.addListener(
        () => observed.add(controller.profile!.preferredDistanceKm),
      );
      await controller.updateOnboarding({'preferredDistanceKm': 60});
      expect(controller.profile!.preferredDistanceKm, 60);
      expect(observed.last, 60);
      api.fail = true;
      await expectLater(
        controller.updateOnboarding({'preferredDistanceKm': 10}),
        throwsException,
      );
      expect(controller.profile!.preferredDistanceKm, 60);
      expect(controller.saving, isFalse);
      controller.dispose();
    },
  );

  testWidgets('Settings displays and saves the shared distance preference', (
    tester,
  ) async {
    final controller = FakeProfileController();
    await controller.updateOnboarding({'preferredDistanceKm': 42});
    await tester.pumpWidget(
      MaterialApp(home: ProfileSettingsScreen(controller: controller)),
    );
    await tester.ensureVisible(find.text('Distance'));
    await tester.tap(find.text('Distance'));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 42);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(60);
    await tester.pump();
    await tester.tap(find.text('Save distance'));
    await tester.pumpAndSettle();
    expect(controller.lastChanges, {'preferredDistanceKm': 60});
    expect(controller.profile!.preferredDistanceKm, 60);
    expect(find.text('60 km'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  test('age changes only on birthday and completeness uses saved data', () {
    final p = MemberProfile(fixture());
    expect(p.ageAt(DateTime(2026, 10, 8)), 25);
    expect(p.ageAt(DateTime(2026, 10, 9)), 26);
    expect(p.strength, 67);
    expect(p.verified, isFalse);
    expect(MemberProfile({'user': {}}).age, isNull);
  });

  testWidgets('profile shows real member details and opens prefilled editing', (
    tester,
  ) async {
    final controller = FakeProfileController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileMainScreen(controller: controller)),
      ),
    );
    expect(find.textContaining('Vinod J'), findsOneWidget);
    expect(find.text('Hyderabad'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit profile'));
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Edit Basic information'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Vinod J'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Hyderabad'), findsOneWidget);
    final languages = find.widgetWithText(TextFormField, 'English, Telugu');
    await tester.ensureVisible(languages);
    expect(languages, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('privacy toggle persists the new value and refreshes the view', (
    tester,
  ) async {
    final controller = FakeProfileController();
    await tester.pumpWidget(
      MaterialApp(home: ProfilePrivacyScreen(controller: controller)),
    );
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(controller.lastChanges, {'showProfile': false});
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('interest limit preserves existing selections', (tester) async {
    final controller = FakeProfileController();
    await tester.pumpWidget(
      MaterialApp(home: ProfileInterestsScreen(controller: controller)),
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Gaming'));
    await tester.pump();
    expect(find.text('Choose up to 5 interests.'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Gaming'))
          .selected,
      isFalse,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Coffee'))
          .selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('work edit saves user-entered values before continuing', (
    tester,
  ) async {
    final controller = FakeProfileController();
    await tester.pumpWidget(
      MaterialApp(home: ProfileEducationWorkScreen(controller: controller)),
    );
    await tester.enterText(find.byType(TextField).first, 'Masters');
    await tester.tap(find.text('Continue →'));
    await tester.pumpAndSettle();
    expect(controller.lastChanges?['education'], 'Masters');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('basic information edits save and return to the edit hub', (
    tester,
  ) async {
    final controller = FakeProfileController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileMainScreen(controller: controller)),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit profile'));
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Basic information'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hyderabad'),
      'Bengaluru',
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(controller.profile!.text('location'), 'Bengaluru');
    expect(find.text('Save changes'), findsNothing);
    expect(find.byType(ProfileEditScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('profile utility screens fit a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = FakeProfileController();
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      for (final screen in [
        Scaffold(body: ProfileMainScreen(controller: controller)),
        ProfileBasicInfoScreen(controller: controller),
        ProfileEducationWorkScreen(controller: controller),
        ProfileAboutMeScreen(controller: controller),
        ProfileInterestsScreen(controller: controller),
        ProfileMoreDetailsScreen(controller: controller),
        ProfileSettingsScreen(controller: controller),
        ProfilePrivacyScreen(controller: controller),
        ProfilePreviewScreen(controller: controller),
        ProfileVerificationScreen(controller: controller),
        ProfileInsightsScreen(controller: controller),
        ProfilePhotoGalleryScreen(controller: controller),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
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
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} at $size',
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
