import 'package:dating_app/features/home/presentation/screens/discover_travel_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens [screen] as a route and returns a getter for the value it pops.
Future<String? Function()> _open(WidgetTester tester, Widget screen) async {
  String? result = 'not popped';
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await Navigator.of(
            context,
          ).push<String>(MaterialPageRoute(builder: (_) => screen)),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  testWidgets('shows cities without made-up counts or a way back', (
    tester,
  ) async {
    await _open(tester, const DiscoverTravelScreen());
    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.textContaining('K people'), findsNothing);
    expect(find.text('Back to my location'), findsNothing);
  });

  testWidgets('back to my location turns travel mode off', (tester) async {
    final result = await _open(
      tester,
      const DiscoverTravelScreen(currentCity: 'Mumbai'),
    );
    final back = find.text('Back to my location');
    await tester.scrollUntilVisible(
      back,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Set Mumbai'), findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(result(), DiscoverTravelScreen.myLocation);
  });

  testWidgets('search matches a city by its state', (tester) async {
    await _open(tester, const DiscoverTravelScreen());
    await tester.enterText(find.byType(TextField), 'telangana');
    await tester.pumpAndSettle();
    expect(find.text('Hyderabad'), findsOneWidget);
    expect(find.text('Warangal'), findsOneWidget);
    expect(find.text('Mumbai'), findsNothing);
    await tester.enterText(find.byType(TextField), 'atlantis');
    await tester.pumpAndSettle();
    expect(find.textContaining('No cities match'), findsOneWidget);
  });
}
