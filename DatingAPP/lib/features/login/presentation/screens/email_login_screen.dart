import 'package:flutter/material.dart';
import '../../data/login_copy.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../widgets/login_header.dart';
import '../widgets/login_heading.dart';
import '../widgets/login_scaffold.dart';
import 'verify_clerk_code_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key, this.initialCreateAccount = false});

  final bool initialCreateAccount;

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  late bool _createAccount = widget.initialCreateAccount;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await VerifyClerkCodeScreen.sendCode(
        context,
        identifier: email,
        isPhone: false,
        createAccount: _createAccount,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LoginScaffold(
    kind: LoginHeaderKind.phone,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginHeading(
          title: _createAccount
              ? LoginCopy.createAccount
              : LoginCopy.enterEmail,
          subtitle: 'We’ll email you a one-time verification code',
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextField(
          controller: _emailController,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _continue(),
          decoration: const InputDecoration(
            labelText: LoginCopy.emailLabel,
            hintText: LoginCopy.emailHint,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: LoginCopy.sendCode,
          isLoading: _busy,
          onPressed: _continue,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _createAccount = !_createAccount;
                  _error = null;
                }),
          child: Text(
            _createAccount
                ? LoginCopy.existingAccount
                : LoginCopy.newToJust2,
          ),
        ),
      ],
    ),
  );
}
