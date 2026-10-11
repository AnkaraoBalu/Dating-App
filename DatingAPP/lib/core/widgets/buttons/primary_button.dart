import 'app_button.dart';

class PrimaryButton extends AppButton {
  const PrimaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.isLoading,
    super.fullWidth,
  }) : super(variant: AppButtonVariant.primary);
}
