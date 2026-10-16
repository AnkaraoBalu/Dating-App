import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/theme/theme.dart';
import '../../data/login_copy.dart';
import '../../data/clerk_operation.dart';
import '../navigation/login_routes.dart';
import '../widgets/login_header.dart';
import '../widgets/login_scaffold.dart';
import '../widgets/social_login_button.dart';
import 'email_login_screen.dart';
import '../../../demo_auth/presentation/screens/demo_login_screen.dart';

// Debug builds always offer demo login; tester release builds opt in with
// --dart-define=SHOW_DEMO_LOGIN=true. Store builds leave it off.
const _showDemoLogin = kDebugMode || bool.fromEnvironment('SHOW_DEMO_LOGIN');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ClerkAuthState? _authState;
  bool _googleBusy = false;
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
        debugPrint('[Just2Auth] Clerk Google OAuth error: ${error.message}');
        if (mounted) setState(() => _authError = error.message);
      }

      // One button for everyone: start as a sign-in and let the OAuth
      // callback transfer new Google identities to sign-up (DatingApp).
      debugPrint('[Just2Auth] Starting Google sign-in or sign-up');
      await runClerkOperation<void>(
        errors: auth.errorStream,
        operation: () async {
          await auth.resetClient();
          if (!mounted) return;
          await auth.ssoSignIn(
            context,
            clerk.Strategy.oauthGoogle,
            onError: onError,
          );
        },
      );
      debugPrint('[Just2Auth] Google browser opened; awaiting OAuth callback');
      if (mounted && auth.isSignedIn) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      debugPrint('[Just2Auth] Google flow threw: $error');
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
              const BrandLogo(height: 78),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Welcome to Just2',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in or create your account in one step.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
              : () => LoginRoutes.push<void>(context, const EmailLoginScreen()),
        ),
        if (_authState == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sign-in is unavailable. Configure the Clerk publishable key and restart the app.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        if (_showDemoLogin) ...[
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
