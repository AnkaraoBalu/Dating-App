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
    expect(find.text('Choose a destination').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Visakhapatnam'),
      300,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Visakhapatnam'), findsOneWidget);
    expect(find.text('Choose a destination').hitTestable(), findsOneWidget);
  });

  testWidgets('back to my location turns travel mode off', (tester) async {
    final result = await _open(
      tester,
      const DiscoverTravelScreen(currentCity: 'Mumbai'),
    );
    final back = find.text('Back to my location');
    // Buttons stay pinned below the scrolling grid, so no scrolling needed.
    expect(find.text('Set Mumbai'), findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(result(), DiscoverTravelScreen.myLocation);
  });
}
