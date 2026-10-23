import 'dart:async';
import 'package:dating_app/features/profile/data/profile_controller.dart';
import 'package:dating_app/features/profile_setup/data/profile_setup_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileApi extends ProfileSetupApi {
  _ProfileApi() : super(baseUrl: '', getSessionToken: () async => 'test');

  @override
  Future<Map<String, dynamic>> load() async => {
    'user': {
      'onboardingProfile': {'interestedIn': 'women', 'preferredDistanceKm': 40},
    },
  };
}

class _Controller extends ProfileController {
  _Controller()
    : super(
        baseUrl: '',
        getSessionToken: () async => 'test',
        profileApi: _ProfileApi(),
      );

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async => throw Exception('Insights unavailable');
}

class _SlowInsightsController extends ProfileController {
  _SlowInsightsController()
    : super(
        baseUrl: '',
        getSessionToken: () async => 'test',
        profileApi: _ProfileApi(),
      );
  final pending = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) => pending.future;
}

class _StalledProfileApi extends ProfileSetupApi {
  _StalledProfileApi()
    : super(baseUrl: '', getSessionToken: () async => 'test');
  final pending = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> load() => pending.future;
}

void main() {
  testWidgets('fallback profile load times out and ignores late results', (
    tester,
  ) async {
    final api = _StalledProfileApi();
    final controller = ProfileController(
      baseUrl: '',
      getSessionToken: () async => 'test',
      profileApi: api,
    );
    unawaited(controller.load());
    await tester.pump(const Duration(seconds: 30));
    expect(controller.loading, isFalse);
    expect(controller.error, contains('TimeoutException'));
    api.pending.complete({'userId': 'late'});
    await tester.pump();
    expect(controller.profile, isNull);
    controller.dispose();
  });

  test('profile readiness does not wait for slow insights', () async {
    final controller = _SlowInsightsController();
    try {
      await controller.load().timeout(const Duration(seconds: 1));
      expect(controller.profile!.discoveryGender, 'woman');
      expect(controller.loading, isFalse);
      expect(controller.pending.isCompleted, isFalse);
    } finally {
      controller.pending.complete({});
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
    }
  });

  test('insights failure preserves onboarding discovery preferences', () async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.profile, isNotNull);
    expect(controller.profile!.discoveryGender, 'woman');
    expect(controller.profile!.preferredDistanceKm, 40);
    expect(controller.error, isNull);
    expect(controller.loading, isFalse);
    expect(controller.insights, isEmpty);
  });
}
