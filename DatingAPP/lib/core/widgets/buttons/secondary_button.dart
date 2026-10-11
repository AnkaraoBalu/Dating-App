import 'app_button.dart';

class SecondaryButton extends AppButton {
  const SecondaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.isLoading,
    super.fullWidth,
  }) : super(variant: AppButtonVariant.secondary);
}
