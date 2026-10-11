import 'dart:async';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import '../../data/login_copy.dart';
import '../../data/clerk_operation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../widgets/login_header.dart';
import '../widgets/login_heading.dart';
import '../widgets/login_scaffold.dart';
import '../widgets/otp_code_field.dart';

class VerifyClerkCodeScreen extends StatefulWidget {
  const VerifyClerkCodeScreen({
    super.key,
    required this.identifier,
    required this.isPhone,
    required this.createAccount,
  });

  final String identifier;
  final bool isPhone;
  final bool createAccount;

  static Future<void> sendCode(
    BuildContext context, {
    required String identifier,
    required bool isPhone,
    required bool createAccount,
  }) async {
    final auth = ClerkAuth.of(context, listen: false);
    final strategy = isPhone
        ? clerk.Strategy.phoneCode
        : clerk.Strategy.emailCode;
    await runClerkOperation<void>(
      errors: auth.errorStream,
      operation: () async {
        // Discard an abandoned OAuth/code attempt before starting a new one.
        await auth.resetClient();
        if (createAccount) {
          await auth.attemptSignUp(
            strategy: strategy,
            phoneNumber: isPhone ? identifier : null,
            emailAddress: isPhone ? null : identifier,
          );
        } else {
          await auth.attemptSignIn(strategy: strategy, identifier: identifier);
        }
      },
    );
    if (auth.isSignedIn) {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VerifyClerkCodeScreen(
          identifier: identifier,
          isPhone: isPhone,
          createAccount: createAccount,
        ),
      ),
    );
  }

  @override
  State<VerifyClerkCodeScreen> createState() => _VerifyClerkCodeScreenState();
}

class _VerifyClerkCodeScreenState extends State<VerifyClerkCodeScreen> {
  final _controller = TextEditingController();
  late ClerkAuthState _auth;
  Timer? _timer;
  DateTime _resendAt = DateTime.now().add(const Duration(seconds: 30));
  int _remaining = 30;
  bool _busy = false;
  String? _error;

  clerk.Strategy get _strategy =>
      widget.isPhone ? clerk.Strategy.phoneCode : clerk.Strategy.emailCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auth = ClerkAuth.of(context, listen: false);
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _resendAt.difference(DateTime.now()).inSeconds.clamp(0, 30);
      setState(() => _remaining = left);
      if (left == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_controller.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await runClerkOperation<void>(
        errors: _auth.errorStream,
        operation: () async {
          if (widget.createAccount) {
            await _auth.attemptSignUp(
              strategy: _strategy,
              phoneNumber: widget.isPhone ? widget.identifier : null,
              emailAddress: widget.isPhone ? null : widget.identifier,
              code: _controller.text.trim(),
            );
          } else {
            await _auth.attemptSignIn(
              strategy: _strategy,
              identifier: widget.identifier,
              code: _controller.text.trim(),
            );
          }
        },
      );
      if (mounted && _auth.isSignedIn) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      if (mounted) {
        setState(
          () => _error =
              'The code was accepted, but sign-in needs another step. Check your Clerk sign-in settings.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _remaining > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await runClerkOperation(
        errors: _auth.errorStream,
        operation: () => _auth.resendCode(_strategy),
      );
      if (!mounted) return;
      _controller.clear();
      _resendAt = DateTime.now().add(const Duration(seconds: 30));
      setState(() => _remaining = 30);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left = _resendAt
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, 30);
        setState(() => _remaining = left);
        if (left == 0) _timer?.cancel();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LoginScaffold(
    kind: LoginHeaderKind.verification,
    child: Column(
      children: [
        LoginHeading(
          title:
              '${LoginCopy.verificationTitle} ${widget.isPhone ? 'number' : 'email'}',
          subtitle: LoginCopy.verificationSubtitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.identifier, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xl),
        OtpCodeField(
          controller: _controller,
          enabled: !_busy,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _verify(),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: LoginCopy.verifyCode,
          isLoading: _busy,
          onPressed: _verify,
        ),
        TextButton(
          onPressed: !_busy && _remaining == 0 ? _resend : null,
          child: Text(
            _remaining == 0
                ? LoginCopy.resendCode
                : LoginCopy.resendCodeIn(_remaining),
          ),
        ),
      ],
    ),
  );
}
