import 'package:dating_app/features/profile_setup/data/profile_setup_api.dart';
import 'package:dating_app/features/profile_setup/presentation/screens/profile_basics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BasicsApi extends ProfileSetupApi {
  BasicsApi()
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token');
  Map<String, Object?> saved = {};
  @override
  Future<Map<String, dynamic>> update(Map<String, Object?> changes) async {
    saved = changes;
    return {...changes};
  }
}

void main() {
  Future<void> pumpBasics(WidgetTester tester, BasicsApi api) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBasicsScreen(api: api, initialValues: const {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('profile-basics-next'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> answerOther(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('other-value-field')),
      value,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('other-value-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('Other opens a popup and saves the typed value', (tester) async {
    final api = BasicsApi();
    await pumpBasics(tester, api);

    // Location (step 1): closing the popup without saving changes nothing.
    await tester.tap(find.text('Other city'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('other-value-save')))
          .onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await answerOther(tester, 'Other city', 'Warangal');
    expect(find.text('Other city: Warangal'), findsOneWidget);

    await next(tester); // education
    await answerOther(tester, 'Other', ' Executive MBA ');
    expect(find.text('Other: Executive MBA'), findsOneWidget);
    await next(tester); // field of study
    await next(tester); // job title
    await answerOther(tester, 'Other', 'Pilot');
    await next(tester); // company
    await answerOther(tester, 'Other', 'Deloitte');
    expect(find.text('Other: Deloitte'), findsOneWidget);

    // Editing reopens the popup with the saved value.
    await tester.tap(find.text('Other: Deloitte'));
    await tester.pumpAndSettle();
    expect(find.text('Deloitte'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('other-value-field')),
      'Deloitte India',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('other-value-save')));
    await tester.pumpAndSettle();

    await next(tester); // height
    await next(tester); // zodiac
    await next(tester); // languages
    await answerOther(tester, 'Other', 'Lambadi');
    expect(find.text('Lambadi'), findsOneWidget);
    expect(find.text('Add another language'), findsOneWidget);
    await next(tester); // summary
    await next(tester); // save

    expect(api.saved['location'], 'Warangal');
    expect(api.saved['education'], 'Executive MBA');
    expect(api.saved['jobTitle'], 'Pilot');
    expect(api.saved['company'], 'Deloitte India');
    expect(api.saved['languages'], ['Lambadi']);
  });
}
