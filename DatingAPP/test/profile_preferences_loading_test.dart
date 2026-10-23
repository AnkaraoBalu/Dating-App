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

void main() {
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
