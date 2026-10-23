import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:app_links/app_links.dart';

import 'auth_startup.dart';
import 'oauth_browser.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/welcome/presentation/screens/welcome_screen.dart';
import '../features/login/presentation/screens/signed_in_gate.dart';
import '../features/demo_auth/data/demo_session.dart';

class DatingApp extends StatelessWidget {
  const DatingApp({super.key, this.clerkPublishableKey = ''});

  final String clerkPublishableKey;

  static const _oauthCallback = 'matchify://auth/oauth';
  static final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  Widget _authEntry() => ValueListenableBuilder<DemoSession?>(
    valueListenable: DemoSession.current,
    builder: (context, demoSession, _) {
      if (demoSession != null) {
        return SignedInGate(
          key: ValueKey('demo:${demoSession.username}'),
          sessionTokenProvider: () async => demoSession.accessToken,
        );
      }
      return clerkPublishableKey.isEmpty
          ? const WelcomeScreen()
          : ClerkAuthBuilder(
              signedInBuilder: (context, auth) => SignedInGate(
                key: ValueKey('clerk:${auth.user?.id}:${auth.session?.id}'),
                auth: auth,
              ),
              signedOutBuilder: (context, auth) => const WelcomeScreen(),
            );
    },
  );

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: AppConstants.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: _authEntry(),
      onGenerateRoute: (settings) {
        if (settings.name == '/oauth') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _authEntry(),
          );
        }
        return null;
      },
    );
    if (clerkPublishableKey.isEmpty) return app;

    return AuthStartup(
      createConfig: () => ClerkAuthConfig(
        publishableKey: clerkPublishableKey,
        telemetryPeriod: Duration.zero,
        defaultLaunchMode: oauthBrowserMode,
        redirectionGenerator: (_, strategy) =>
            strategy.isOauth ? Uri.parse(_oauthCallback) : null,
      ),
      child: _ClerkOAuthCallback(child: app),
    );
  }
}

class _ClerkOAuthCallback extends StatefulWidget {
  const _ClerkOAuthCallback({required this.child});

  final Widget child;

  @override
  State<_ClerkOAuthCallback> createState() => _ClerkOAuthCallbackState();
}

class _ClerkOAuthCallbackState extends State<_ClerkOAuthCallback> {
  StreamSubscription<Uri>? _subscription;
  StreamSubscription<clerk.ClerkError>? _errorsSubscription;
  String? _lastCallback;
  String? _callbackError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription != null) return;
    final links = AppLinks();
    final auth = ClerkAuth.of(context, listen: false);
    _errorsSubscription = auth.errorStream.listen((error) {
      debugPrint('[Just2Auth] Clerk error: ${error.message}');
      _callbackError = error.message;
    });
    _subscription = links.uriLinkStream.listen(_handleLink);
    unawaited(
      links.getInitialLink().then((uri) {
        if (uri != null && mounted) _handleLink(uri);
      }),
    );
  }

  Future<void> _handleLink(Uri uri) async {
    if (!mounted ||
        uri.scheme != 'matchify' ||
        uri.host != 'auth' ||
        uri.path != '/oauth' ||
        uri.toString() == _lastCallback) {
      return;
    }
    _lastCallback = uri.toString();
    unawaited(dismissOAuthBrowser());
    final auth = ClerkAuth.of(context, listen: false);
    if (auth.isSignedIn) return;
    _callbackError = null;
    debugPrint(
      '[Just2Auth] OAuth callback received; '
      'pending sign-up=${auth.signUp != null}, '
      'pending sign-in=${auth.signIn != null}, '
      'has callback token=${uri.queryParameters.containsKey('rotating_token_nonce')}',
    );
    try {
      final token = uri.queryParameters['rotating_token_nonce'];
      if (token != null) {
        try {
          await auth.completeOAuthSignIn(token: token);
        } catch (error) {
          // A new Google identity makes the sign-in fail with
          // "external_account_not_found" while Clerk marks it transferable.
          // Reload the attempt and fall through to the transfer below
          // instead of stopping on that error.
          debugPrint('[Just2Auth] OAuth completion failed: $error');
          await auth.refreshClient();
        }
      } else {
        await auth.refreshClient();
      }
      // A Google identity can land in the opposite flow from the selected
      // button (new identity during sign-in, or existing identity during
      // sign-up). Clerk marks that state transferable; continue in the
      // matching flow instead of leaving the user on the login screen.
      if (!auth.isSignedIn &&
          (auth.signIn?.isTransferable == true ||
              auth.signUp?.isTransferable == true)) {
        debugPrint(
          '[Just2Auth] Google identity is transferable; switching '
          'between sign-in and sign-up.',
        );
        await auth.transfer();
      }
      // A new Google identity can come back with the sign-in waiting at
      // `needs_identifier` and not marked transferable on the client, even
      // though Clerk has prepared the sign-up. Ask Clerk to transfer anyway;
      // it refuses when there is nothing to transfer.
      final pendingSignIn = auth.signIn;
      if (!auth.isSignedIn && auth.signUp == null && pendingSignIn != null) {
        final verification = pendingSignIn.firstFactorVerification;
        debugPrint(
          '[Just2Auth] Sign-in not complete; status=${pendingSignIn.status.name}, '
          'verification=${verification?.status.name ?? 'none'}, '
          'error=${verification?.errorMessage ?? 'none'}. Trying sign-up transfer.',
        );
        try {
          await auth.transferToSignUp();
        } catch (error) {
          debugPrint('[Just2Auth] Sign-up transfer failed: $error');
        }
      }
      if (!auth.isSignedIn) await auth.refreshClient();
      debugPrint(
        '[Just2Auth] OAuth callback completed; '
        'signedIn=${auth.isSignedIn}, '
        'signUpStatus=${auth.signUp?.status.name ?? 'none'}, '
        'signInStatus=${auth.signIn?.status.name ?? 'none'}',
      );
      final signUp = auth.signUp;
      if (signUp != null && !auth.isSignedIn) {
        debugPrint(
          '[Just2Auth] Sign-up requirements: '
          'missing=${signUp.missingFields.map((field) => field.name).join(', ')}, '
          'unverified=${signUp.unverifiedFields.map((field) => field.name).join(', ')}, '
          'required=${signUp.requiredFields.map((field) => field.name).join(', ')}',
        );
      }
      if (!auth.isSignedIn) {
        _showError(
          signUp != null
              ? _signUpRequirementsMessage(signUp)
              : _callbackError ?? _signUpRequirementsMessage(null),
        );
      }
    } catch (error) {
      debugPrint('[Just2Auth] OAuth callback failed: $error');
      _showError(error.toString());
    }
  }

  String _signUpRequirementsMessage(clerk.SignUp? signUp) {
    if (signUp == null) {
      return 'Google sign-in did not complete. Check the Clerk log for this attempt.';
    }
    if (signUp.missingFields.isNotEmpty) {
      final fields = signUp.missingFields
          .map((field) => field.title)
          .join(', ');
      return 'Another step is required to create your account: $fields. '
          'Check which fields are required in Clerk sign-up settings.';
    }
    if (signUp.unverifiedFields.isNotEmpty) {
      final fields = signUp.unverifiedFields
          .map((field) => field.title)
          .join(', ');
      return 'Your account still needs verification for: $fields.';
    }
    return 'Clerk has not finished creating your account. Check the sign-up event in Clerk logs.';
  }

  void _showError(String message) {
    DatingApp._messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _errorsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
