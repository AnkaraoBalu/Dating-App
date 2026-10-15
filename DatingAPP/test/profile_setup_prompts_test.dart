import 'package:dating_app/features/profile_setup/data/profile_setup_api.dart';
import 'package:dating_app/features/profile_setup/data/profile_setup_copy.dart';
import 'package:dating_app/features/profile_setup/data/profile_setup_options.dart';
import 'package:dating_app/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PromptsProfileApi extends ProfileSetupApi {
  PromptsProfileApi()
    : super(baseUrl: 'http://unused', getSessionToken: () async => 'token');
  List<Map<String, String>> saved = [];
  @override
  Future<Map<String, dynamic>> load() async => {
    'photos': [
      for (var i = 0; i < 4; i++)
        {'id': '$i', 'secureUrl': 'https://example.test/$i.png'},
    ],
    'prompts': saved,
    'user': <String, dynamic>{'firstName': 'Vinod'},
  };
  @override
  Future<Map<String, dynamic>> update(Map<String, Object?> changes) => load();
  @override
  Future<Map<String, dynamic>> savePrompts(List<Map<String, String>> prompts) {
    saved = prompts;
    return load();
  }
}

void main() {
  final prompt = ProfileSetupOptions.promptSections.values.first.first;

  Future<void> next(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('profile-setup-next'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<PromptsProfileApi> openPickStep(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = PromptsProfileApi();
    await tester.pumpWidget(MaterialApp(home: ProfileSetupScreen(api: api)));
    await tester.pumpAndSettle();
    for (var step = 0; step < 4; step++) {
      await next(tester);
    }
    expect(find.text(ProfileSetupCopy.titles[4]), findsOneWidget);
    return api;
  }

  testWidgets('a prompt is added only after its answer is saved in the popup', (
    tester,
  ) async {
    final api = await openPickStep(tester);
    await tester.tap(find.text(prompt));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('prompt-answer-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    // Closing the popup without saving leaves the prompt unselected.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('0/5 selected'), findsOneWidget);

    await tester.tap(find.text(prompt));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('prompt-answer-field')),
      '  Sunday chai on the terrace  ',
    );
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('1/5 selected'), findsOneWidget);
    expect(find.text('Sunday chai on the terrace'), findsOneWidget);

    await next(tester);
    expect(find.text(ProfileSetupCopy.titles[5]), findsOneWidget);
    await next(tester);
    await next(tester);
    expect(api.saved, [
      {'question': prompt, 'answer': 'Sunday chai on the terrace'},
    ]);
  });

  testWidgets('prompts are optional and an answer can be removed', (
    tester,
  ) async {
    final api = await openPickStep(tester);
    await tester.tap(find.text(prompt));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('prompt-answer-field')),
      'Coffee first',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('prompt-answer-save')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(prompt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove prompt'));
    await tester.pumpAndSettle();
    expect(find.text('0/5 selected'), findsOneWidget);

    // With no prompts, the flow still continues past the answers and preview.
    await next(tester);
    await next(tester);
    await next(tester);
    expect(find.text(ProfileSetupCopy.titles[7]), findsOneWidget);
    expect(api.saved, isEmpty);
  });
}
