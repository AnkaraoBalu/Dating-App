import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/login_copy.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../data/preview_login_service.dart';
import '../../models/verification_challenge.dart';
import '../../validators/login_validators.dart';
import '../widgets/login_header.dart';
import '../widgets/login_heading.dart';
import '../widgets/login_preview_note.dart';
import '../widgets/login_scaffold.dart';
import '../widgets/otp_code_field.dart';

class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({
    super.key,
    required this.challenge,
    this.service = const PreviewLoginService(),
    this.onVerified,
    this.now = DateTime.now,
  });
  final VerificationChallenge challenge;
  final PreviewLoginService service;
  final VoidCallback? onVerified;
  final DateTime Function() now;
  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  late DateTime _resendAt;
  int _remaining = 30;
  bool _busy = false;
  String? _error;
  late VerificationChallenge _challenge;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _resendAt = widget.now().add(const Duration(seconds: 30));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final seconds = (_resendAt.difference(widget.now()).inMilliseconds / 1000)
          .ceil()
          .clamp(0, 30);
      setState(() => _remaining = seconds);
      if (seconds == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_busy || _remaining > 0) return;
    setState(() => _busy = true);
    final challenge = await widget.service.requestCode(_challenge.phoneNumber);
    if (!mounted) return;
    setState(() {
      _challenge = challenge;
      _busy = false;
      _error = null;
      _controller.clear();
      _remaining = 30;
      _resendAt = widget.now().add(const Duration(seconds: 30));
    });
    _startTimer();
  }

  Future<void> _verify() async {
    if (_busy) return;
    final error = LoginValidators.code(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final accepted = await widget.service.verify(_challenge, _controller.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!accepted) {
      setState(
        () => _error = 'That code does not match. Try the preview code below.',
      );
      return;
    }
    if (widget.onVerified != null) {
      Navigator.of(context).pop();
      widget.onVerified!();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.forest,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Preview complete', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'You explored the login flow. No account has been created.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Done',
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LoginScaffold(
    kind: LoginHeaderKind.verification,
    child: Column(
      children: [
        const LoginHeading(
          title: '${LoginCopy.verificationTitle} number',
          subtitle: LoginCopy.verificationSubtitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_challenge.phoneNumber, style: AppTypography.label),
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
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.forestDark,
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: LoginCopy.verifyCode,
          isLoading: _busy,
          onPressed: _verify,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _remaining == 0 && !_busy ? _resend : null,
          child: Text(
            _remaining == 0
                ? LoginCopy.resendCode
                : LoginCopy.resendCodeIn(_remaining),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LoginPreviewNote(code: _challenge.previewCode),
        const SizedBox(height: AppSpacing.xl),
        const ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 6, color: AppColors.peach),
              SizedBox(width: 10),
              Icon(Icons.circle, size: 6, color: AppColors.coralSoft),
              SizedBox(width: 10),
              Icon(Icons.circle, size: 6, color: AppColors.borderStrong),
              SizedBox(width: 10),
              Icon(Icons.circle, size: 10, color: AppColors.forest),
            ],
          ),
        ),
      ],
    ),
  );
}
