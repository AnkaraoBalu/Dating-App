import 'app_button.dart';

class LoveButton extends AppButton {
  const LoveButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.isLoading,
    super.fullWidth,
  }) : super(variant: AppButtonVariant.love);
}
