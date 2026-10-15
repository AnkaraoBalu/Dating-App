import 'dart:convert';

import 'package:dating_app/features/home/data/home_discovery_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'legacy local distance and gender are removed while other filters survive',
    () async {
      final storage = SharedPreferencesAsync();
      await storage.setString(
        'home_discovery_preferences_v1',
        jsonEncode({
          'radiusKm': 99,
          'minAge': 24,
          'maxAge': 40,
          'gender': 'woman',
          'interests': ['coffee'],
          'travelLocation': 'Mumbai',
        }),
      );
      final store = HomeDiscoveryPreferencesStore(preferences: storage);
      final loaded = await store.load();
      await store.save(loaded);
      final saved =
          jsonDecode(
                (await storage.getString('home_discovery_preferences_v1'))!,
              )
              as Map;
      expect(saved.containsKey('radiusKm'), isFalse);
      expect(saved['minAge'], 24);
      expect(saved['maxAge'], 40);
      expect(saved.containsKey('gender'), isFalse);
      expect(saved['interests'], ['coffee']);
      expect(saved['travelLocation'], 'Mumbai');
    },
  );
}
