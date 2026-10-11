import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';
import '../../data/login_copy.dart';
import '../../data/clerk_operation.dart';
import '../navigation/login_routes.dart';
import '../widgets/login_header.dart';
import '../widgets/login_scaffold.dart';
import '../widgets/social_login_button.dart';
import 'email_login_screen.dart';
import '../../../demo_auth/presentation/screens/demo_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ClerkAuthState? _authState;
  bool _googleBusy = false;
  bool _createAccount = false;
  String? _authError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.findAncestorWidgetOfExactType<ClerkAuth>() == null
        ? null
        : ClerkAuth.of(context, listen: false);
    if (identical(auth, _authState)) return;
    _authState?.removeListener(_handleAuthChanged);
    _authState = auth;
    auth?.addListener(_handleAuthChanged);
  }

  void _handleAuthChanged() {
    if (!mounted || _authState?.isSignedIn != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _authState?.isSignedIn == true) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _authState?.removeListener(_handleAuthChanged);
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    if (_googleBusy) return;
    setState(() {
      _googleBusy = true;
      _authError = null;
    });
    try {
      final auth = ClerkAuth.of(context, listen: false);
      void onError(clerk.ClerkError error) {
        debugPrint('[MatchifyAuth] Clerk Google OAuth error: ${error.message}');
        if (mounted) setState(() => _authError = error.message);
      }

      debugPrint(
        '[MatchifyAuth] Starting Google ${_createAccount ? 'sign-up' : 'sign-in'}',
      );
      await runClerkOperation<void>(
        errors: auth.errorStream,
        operation: () async {
          await auth.resetClient();
          if (!mounted) return;
          if (_createAccount) {
            await auth.ssoSignUp(
              context,
              clerk.Strategy.oauthGoogle,
              onError: onError,
            );
          } else {
            await auth.ssoSignIn(
              context,
              clerk.Strategy.oauthGoogle,
              onError: onError,
            );
          }
        },
      );
      debugPrint(
        '[MatchifyAuth] Google browser opened; awaiting OAuth callback',
      );
      if (mounted && auth.isSignedIn) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      debugPrint('[MatchifyAuth] Google flow threw: $error');
      if (mounted) {
        setState(() => _authError = error.toString());
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _information(BuildContext context, String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTypography.h2, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LoginScaffold(
    kind: LoginHeaderKind.social,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.asset(AppAssets.logo, width: 64, height: 64),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppConstants.name,
                style: AppTypography.hero,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _createAccount ? 'Create your account' : 'Welcome back',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('Sign in')),
            ButtonSegment<bool>(value: true, label: Text('Create account')),
          ],
          selected: {_createAccount},
          onSelectionChanged: _googleBusy
              ? null
              : (selection) => setState(() {
                  _createAccount = selection.first;
                  _authError = null;
                }),
        ),
        const SizedBox(height: AppSpacing.lg),
        SocialLoginButton(
          provider: LoginProvider.google,
          onPressed: _googleBusy || _authState == null ? null : _googleSignIn,
        ),
        if (_authError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _authError!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SocialLoginButton(
          provider: LoginProvider.email,
          onPressed: _googleBusy || _authState == null
              ? null
              : () => LoginRoutes.push<void>(
                  context,
                  EmailLoginScreen(initialCreateAccount: _createAccount),
                ),
        ),
        if (_authState == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sign-in is unavailable. Configure the Clerk publishable key and restart the app.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () =>
                LoginRoutes.push<void>(context, const DemoLoginScreen()),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Continue with a demo user'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          LoginCopy.brandAgreement,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () => _information(
                context,
                LoginCopy.terms,
                LoginCopy.termsUnavailable,
              ),
              child: const Text(LoginCopy.terms),
            ),
            TextButton(
              onPressed: () => _information(
                context,
                LoginCopy.privacyPolicy,
                LoginCopy.privacyUnavailable,
              ),
              child: const Text(LoginCopy.privacyPolicy),
            ),
          ],
        ),
      ],
    ),
  );
}
