// Run: flutter test tool/store_screenshots_test.dart
// Captures production widgets using bundled sample content, without a backend.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/core/theme/theme.dart';
import 'package:dating_app/features/home/data/discover_api.dart';
import 'package:dating_app/features/home/data/home_discover_data.dart';
import 'package:dating_app/features/home/presentation/screens/discover_people_screen.dart';
import 'package:dating_app/features/home/presentation/screens/discover_filters_screen.dart';
import 'package:dating_app/features/home/presentation/screens/profile_detail_screen.dart';
import 'package:dating_app/features/onboarding/data/onboarding_api.dart';
import 'package:dating_app/features/onboarding/models/onboarding_profile.dart';
import 'package:dating_app/features/onboarding/presentation/screens/onboarding_questions_screen.dart';
import 'package:dating_app/features/welcome/presentation/screens/welcome_screen.dart';

class _SampleDiscoverApi extends DiscoverApi {
  _SampleDiscoverApi() : super(baseUrl: '', getSessionToken: () async => '');

  @override
  Future<List<HomePerson>> discover({
    String mode = 'for_you', int minAge = 18, int maxAge = 70,
    String? gender, String? location, String? interest,
    List<String> interests = const [], double? latitude, double? longitude,
    int? radiusKm, bool onlineOnly = false, bool verifiedOnly = false,
    int limit = 60,
    void Function(String? reason)? onEmptyReason,
    String? replayBefore,
    void Function(String? token)? onReplayBefore,
  }) async => [HomeDiscoverData.lead, ...HomeDiscoverData.nearby];
}

void main() {
  testWidgets('Export store screenshots from real app widgets', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      for (final entry in {
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'Manrope': 'assets/fonts/manrope/Manrope.ttf',
        'DMSerifDisplay': 'assets/fonts/dm_serif_display/DMSerifDisplay-Regular.ttf',
        'Caveat': 'assets/fonts/caveat/Caveat.ttf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
      }
      final emoji = await File('/System/Library/Fonts/Apple Color Emoji.ttc').readAsBytes();
      await ui.loadFontFromList(emoji, fontFamily: 'ScreenshotEmoji');
      final symbols = await File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf').readAsBytes();
      await ui.loadFontFromList(symbols, fontFamily: 'ScreenshotSymbols');
    });

    Future<void> capture(String name, Widget screen) async {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(debugShowCheckedModeBanner: false,
          theme: AppTheme.light.copyWith(textTheme: AppTheme.light.textTheme.apply(fontFamilyFallback: ['ScreenshotEmoji', 'ScreenshotSymbols'])), home: screen),
      ));
      await tester.pumpAndSettle();
      // Asset decoding runs outside the test clock. Wait for every visible image.
      await tester.runAsync(() async {
        final context = key.currentContext!;
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/store-screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }

    final discover = _SampleDiscoverApi();
    addTearDown(discover.dispose);
    final onboarding = OnboardingApi(baseUrl: '', getSessionToken: () async => '');
    await capture('01-discover-nearby', DiscoverPeopleScreen(
      mode: DiscoverPeopleMode.nearby, api: discover));
    await capture('02-profile', const ProfileDetailScreen(person: HomeDiscoverData.lead));
    await capture('03-welcome', const WelcomeScreen());
    await capture('04-discovery-preferences', const DiscoverFiltersScreen());
    OnboardingProfile profile({List<String> fridays = const []}) => OnboardingProfile(
      username: 'Alex', birthDate: DateTime(2000, 4, 12), genderIdentity: 'woman',
      interestedIn: 'everyone', vibeTypes: const ['sunshine'], idealFridays: fridays);
    await capture('05-ideal-friday', OnboardingQuestionsScreen(
      api: onboarding, initialProfile: profile()));
    await capture('06-your-interests', OnboardingQuestionsScreen(
      api: onboarding, initialProfile: profile(fridays: ['movie_and_food'])));
  });
}
