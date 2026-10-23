import 'dart:convert';

import 'package:dating_app/features/home/data/home_discovery_preferences.dart';
import 'package:dating_app/features/home/presentation/screens/discover_filters_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('the verified-only switch is hidden until verification ships', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscoverFiltersScreen(
          initial: DiscoverFilterOptions(verifiedOnly: true),
        ),
      ),
    );
    expect(find.text('Verified profiles only'), findsNothing);
  });

  test('a saved verified-only filter no longer empties the feed', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await SharedPreferencesAsync().setString(
      'home_discovery_preferences_v1',
      jsonEncode({'verifiedOnly': true}),
    );
    final preferences = await HomeDiscoveryPreferencesStore().load();
    expect(preferences.verifiedOnly, isFalse);
  });
}
