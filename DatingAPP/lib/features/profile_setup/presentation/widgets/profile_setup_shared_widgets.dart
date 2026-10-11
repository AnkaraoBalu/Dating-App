part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupSharedWidgets on _ProfileSetupScreenState {
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.85),
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(15),
  );

  Widget _tipBox(String heading, List<String> tips) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: AppTypography.label),
        const SizedBox(height: 8),
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: AppTypography.bodySmall)),
              ],
            ),
          ),
      ],
    ),
  );
}
