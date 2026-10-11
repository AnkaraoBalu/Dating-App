import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/theme.dart';
import '../../data/login_copy.dart';
import '../../data/phone_countries.dart';
import '../../models/phone_country.dart';
import '../../validators/login_validators.dart';
import '../widgets/login_header.dart';
import '../widgets/login_heading.dart';
import '../widgets/login_scaffold.dart';
import '../widgets/country_picker_button.dart';
import 'verify_clerk_code_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  PhoneCountry _country = PhoneCountries.all.first;
  bool _busy = false;
  bool _createAccount = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await VerifyClerkCodeScreen.sendCode(
        context,
        identifier: '${_country.dialCode}${_controller.text}',
        isPhone: true,
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
    child: Form(
      key: _form,
      child: Column(
        children: [
          LoginHeading(
            title: _createAccount
                ? LoginCopy.createAccount
                : LoginCopy.enterPhone,
            subtitle: "We'll send you a verification code",
          ),
          const SizedBox(height: AppSpacing.xxl),
          LayoutBuilder(
            builder: (context, constraints) {
              final country = CountryPickerButton(
                country: _country,
                enabled: !_busy,
                onSelected: (value) => setState(() => _country = value),
              );
              final field = TextFormField(
                key: const ValueKey('phone-number'),
                controller: _controller,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (value) => LoginValidators.phone(value, _country),
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: LoginCopy.phoneLabel,
                  hintText: LoginCopy.phoneHint,
                ),
              );
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    country,
                    const SizedBox(height: AppSpacing.sm),
                    field,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  country,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: field),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.filled(
              tooltip: 'Send verification code',
              onPressed: _busy ? null : _submit,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: AppColors.textOnDark,
                minimumSize: const Size.square(AppSizes.circleAction),
              ),
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
            ),
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
                  : LoginCopy.newToMatchify,
            ),
          ),
        ],
      ),
    ),
  );
}
