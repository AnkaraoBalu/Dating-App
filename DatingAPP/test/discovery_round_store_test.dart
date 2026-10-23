import 'package:dating_app/features/home/data/discovery_round_store.dart';
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
    'reopening preserves a round until the member explicitly starts another',
    () async {
      final first = DiscoveryRoundStore();
      const cutoff = '2026-01-01T00:00:00.000Z';
      await first.save('https://api.test', 'member-a', cutoff);
      final reopened = DiscoveryRoundStore();
      expect(await reopened.load('https://api.test', 'member-a'), cutoff);
      const next = '2026-01-02T00:00:00.000Z';
      await reopened.save('https://api.test', 'member-a', next);
      expect(await first.load('https://api.test', 'member-a'), next);
    },
  );

  test('members and backend environments never share rounds', () async {
    final store = DiscoveryRoundStore();
    await store.save(
      'https://api.test',
      'member-a',
      '2026-01-01T00:00:00.000Z',
    );
    expect(await store.load('https://api.test', 'member-b'), isNull);
    expect(await store.load('https://staging.test', 'member-a'), isNull);
  });

  test('corrupt and future cutoffs are ignored', () async {
    final store = DiscoveryRoundStore(preferences: SharedPreferencesAsync());
    await store.save('api', 'member', 'broken');
    expect(await store.load('api', 'member'), isNull);
    await store.save(
      'api',
      'member',
      DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String(),
    );
    expect(await store.load('api', 'member'), isNull);
  });
}
