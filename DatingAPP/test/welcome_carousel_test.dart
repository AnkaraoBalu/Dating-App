import 'package:dating_app/app/dating_app.dart';
import 'package:dating_app/core/theme/theme.dart';
import 'package:dating_app/features/welcome/data/welcome_slides.dart';
import 'package:dating_app/features/welcome/presentation/screens/welcome_carousel_screen.dart';
import 'package:dating_app/features/welcome/presentation/widgets/welcome_slide_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('get started opens the four-page carousel', (tester) async {
    await tester.pumpWidget(const DatingApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeCarouselScreen), findsOneWidget);
    expect(find.text(WelcomeSlides.all.first.title), findsOneWidget);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dots jump directly; final arrow completes with reduced motion', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: WelcomeCarouselScreen(onComplete: () => completed++),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Page 4 of 4'));
    await tester.pumpAndSettle();
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text(WelcomeSlides.all.last.title), findsOneWidget);
    await tester.tap(find.byTooltip("Let's begin"));
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('all slides fit $size with large text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final slide in WelcomeSlides.all) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: WelcomeSlidePage(slide: slide)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text(slide.description), 200);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
