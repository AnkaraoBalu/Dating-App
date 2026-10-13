import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../onboarding/data/onboarding_api.dart';
import '../../../onboarding/models/onboarding_profile.dart';
import '../../../onboarding/presentation/screens/onboarding_complete_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_questions_screen.dart';
import '../../../profile_setup/data/profile_setup_api.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/data/discover_api.dart';
import 'location_screen.dart';

class SignedInGate extends StatefulWidget {
  const SignedInGate({super.key, this.auth, this.sessionTokenProvider});

  final ClerkAuthState? auth;
  final Future<String> Function()? sessionTokenProvider;

  @override
  State<SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<SignedInGate> {
  String? _error;
  bool _loading = true;
  OnboardingApi? _api;
  OnboardingProfile? _profile;
  Map<String, dynamic>? _savedProfile;

  @override
  void initState() {
    super.initState();
    _syncUser();
  }

  Future<void> _syncUser() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    var phase = 'starting';
    try {
      final apiUrl = (dotenv.env['API_URL'] ?? dotenv.env['VITE_API_URL'] ?? '')
          .trim()
          .replaceFirst(RegExp(r'/$'), '');
      if (apiUrl.isEmpty) throw Exception('Set API_URL in DatingAPP/.env.');

      final api = OnboardingApi(
        baseUrl: apiUrl,
        getSessionToken: _sessionToken,
      );
      phase = 'loading your Just2 account';
      final profile = await api.loadProfile();
      Map<String, dynamic>? savedProfile;
      if (profile?.completedAt != null) {
        phase = 'loading your dating profile';
        final profileApi = ProfileSetupApi(
          baseUrl: api.baseUrl,
          getSessionToken: api.getSessionToken,
        );
        savedProfile = await profileApi.load();
      }
      _api = api;
      _profile = profile;
      _savedProfile = savedProfile;
      debugPrint(
        '[Just2Auth] API session verified; account data loaded. '
        'onboardingComplete=${profile?.completedAt != null}, '
        'profileComplete=${savedProfile?['completedAt'] != null}.',
      );
    } catch (error) {
      final message = error is TimeoutException
          ? 'Timed out while $phase. Check that the API server is reachable from this device and responsive, then try again.'
          : 'Could not finish $phase: $error';
      debugPrint('[Just2Auth] Startup failed while $phase: $error');
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String> _sessionToken() async {
    final provider = widget.sessionTokenProvider;
    if (provider != null) return provider();
    final auth = widget.auth;
    if (auth == null)
      throw StateError('No authenticated session is available.');
    return (await auth.sessionToken()).jwt;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 44),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Could not finish account setup',
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(label: 'Try again', onPressed: _syncUser),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final profile = _profile;
    final api = _api!;
    if (profile?.completedAt != null) {
      final saved = _savedProfile;
      if (saved?['completedAt'] != null) {
        final user = saved?['user'] as Map<String, dynamic>?;
        final displayName = (user?['username'] as String? ?? '').trim();
        final photos = (saved?['photos'] as List<dynamic>? ?? [])
            .map((photo) => (photo as Map<String, dynamic>)['secureUrl'])
            .whereType<String>()
            .toList();
        return HomeScreen(
          discoverApi: DiscoverApi(
            baseUrl: api.baseUrl,
            getSessionToken: api.getSessionToken,
          ),
          displayName: displayName.isEmpty ? 'Your profile' : displayName,
          location: saved?['location'] as String?,
          photos: photos,
          bio: saved?['bio'] as String? ?? '',
          fieldOfStudy: saved?['fieldOfStudy'] as String?,
        );
      }
      return OnboardingCompleteScreen(
        genderIdentity: profile?.genderIdentity,
        profileApi: ProfileSetupApi(
          baseUrl: api.baseUrl,
          getSessionToken: api.getSessionToken,
        ),
      );
    }
    // Location is the first onboarding screen after sign-in. The saved
    // permission value records the user's choice; it does not reorder setup.
    return LocationScreen(
      onAllow: (latitude, longitude) => _continueToQuestions(
        api,
        true,
        latitude: latitude,
        longitude: longitude,
      ),
      onSkip: () => _continueToQuestions(api, false),
    );
  }

  Future<void> _continueToQuestions(
    OnboardingApi api,
    bool locationGranted, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final profile = await api.updateLocationPermission(
        locationGranted,
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              OnboardingQuestionsScreen(api: api, initialProfile: profile),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your setup: $error')),
        );
      }
    }
  }
}
