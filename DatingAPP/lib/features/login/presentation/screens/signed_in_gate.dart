import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/network/retrying_client.dart';
import '../../../../core/network/server_warmup.dart';
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
  const SignedInGate({
    super.key,
    this.auth,
    this.sessionTokenProvider,
    this.onboardingApi,
    this.profileApi,
  });

  final ClerkAuthState? auth;
  final OnboardingApi? onboardingApi;
  final ProfileSetupApi? profileApi;
  final Future<String> Function()? sessionTokenProvider;

  @override
  State<SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<SignedInGate> {
  // Bound retries so an unavailable API does not trap users on startup.
  static const _maxAttempts = 2;

  int _run = 0;
  String? _error;
  String? _status;
  bool _loading = true;
  String _phase = 'starting';
  OnboardingApi? _api;
  OnboardingProfile? _profile;
  Map<String, dynamic>? _savedProfile;

  @override
  void initState() {
    super.initState();
    _syncUser();
  }

  @override
  void dispose() {
    _run++;
    super.dispose();
  }

  Future<void> _syncUser() async {
    final run = ++_run;
    var active = true;
    bool current() => mounted && run == _run && active;
    setState(() {
      _loading = true;
      _error = null;
      _status = 'Loading your account...';
    });
    _phase = 'starting';
    final watch = Stopwatch()..start();
    try {
      final apiUrl = (dotenv.env['API_URL'] ?? dotenv.env['VITE_API_URL'] ?? '')
          .trim()
          .replaceFirst(RegExp(r'/$'), '');
      if (apiUrl.isEmpty) throw Exception('Set API_URL in DatingAPP/.env.');
      final api =
          widget.onboardingApi ??
          OnboardingApi(baseUrl: apiUrl, getSessionToken: _sessionToken);
      final result = await (() async {
        for (var attempt = 1; ; attempt++) {
          if (!current()) throw StateError('Startup attempt ended.');
          try {
            return await _loadAccount(api, (phase) {
              if (current()) _phase = phase;
            }, current);
          } catch (error) {
            if (!current() ||
                attempt >= _maxAttempts ||
                !isTransientNetworkError(error)) {
              rethrow;
            }
            debugPrint(
              '[Just2Auth] Attempt $attempt failed while $_phase: $error; retrying.',
            );
            setState(
              () =>
                  _status = 'Waking things up. This can take up to a minute...',
            );
            if (error is TimeoutException &&
                error.message?.contains('GET /users/me') == true) {
              await ServerWarmup.ping().timeout(
                const Duration(seconds: 60),
                onTimeout: () {},
              );
            } else {
              unawaited(ServerWarmup.ping());
              await Future<void>.delayed(const Duration(seconds: 2));
            }
          }
        }
      })().timeout(const Duration(seconds: 90));
      if (!current()) return;
      _api = api;
      _profile = result.profile;
      _savedProfile = result.savedProfile;
    } catch (error) {
      if (!current()) return;
      final message = isTransientNetworkError(error)
          ? 'We could not reach Just2 while $_phase. The server may still be starting. Please try again.'
          : 'Could not finish $_phase: $error';
      debugPrint('[Just2Auth] Startup failed while $_phase: $error');
      setState(() => _error = message);
    } finally {
      // Futures are not cancelled by timeout. Invalidate callbacks from late work.
      active = false;
      debugPrint(
        '[Startup] Account gate finished in ${watch.elapsedMilliseconds}ms; phase=$_phase',
      );
      if (mounted && run == _run) setState(() => _loading = false);
    }
  }

  Future<({OnboardingProfile? profile, Map<String, dynamic>? savedProfile})>
  _loadAccount(
    OnboardingApi api,
    void Function(String) phase,
    bool Function() current,
  ) async {
    phase('loading your Just2 account');
    final watch = Stopwatch()..start();
    final profile = await api.loadProfile();
    if (!current()) throw StateError('Startup attempt ended.');
    debugPrint('[Startup] Account loaded in ${watch.elapsedMilliseconds}ms');
    Map<String, dynamic>? savedProfile;
    if (profile?.completedAt != null) {
      phase('loading your dating profile');
      final profileApi =
          widget.profileApi ??
          ProfileSetupApi(
            baseUrl: api.baseUrl,
            getSessionToken: api.getSessionToken,
          );
      watch.reset();
      savedProfile = await profileApi.load();
      debugPrint(
        '[Startup] Dating profile loaded in ${watch.elapsedMilliseconds}ms',
      );
    }
    return (profile: profile, savedProfile: savedProfile);
  }

  Future<String> _sessionToken() async {
    final watch = Stopwatch()..start();
    try {
      final provider = widget.sessionTokenProvider;
      if (provider != null) {
        return await provider().timeout(const Duration(seconds: 10));
      }
      final auth = widget.auth;
      if (auth == null) {
        throw StateError('No authenticated session is available.');
      }
      return (await auth.sessionToken().timeout(
        const Duration(seconds: 10),
      )).jwt;
    } finally {
      // Every API request asks for the token, and cached ones return
      // instantly, so only slow fetches are worth logging.
      if (watch.elapsedMilliseconds >= 300) {
        debugPrint(
          '[Startup] Session token request finished in ${watch.elapsedMilliseconds}ms',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final status = _status;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (status != null) ...[
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(status, textAlign: TextAlign.center),
                ),
              ],
            ],
          ),
        ),
      );
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
                    'Could not load your account',
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
          initialProfile: saved,
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
