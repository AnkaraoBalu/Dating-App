part of '../screens/onboarding_questions_screen.dart';

extension _OnboardingIntroSection on _OnboardingQuestionsScreenState {
  List<String> get _introPortraits {
    const boys = [
      'assets/images/boys-images/rooftop_sunset_portrait.png',
      'assets/images/boys-images/cafe_smiling_portrait.png',
      'assets/images/boys-images/sunset_jacket_portrait.png',
    ];
    const girls = [
      'assets/images/girls-images/golden_hour_portrait.png',
      'assets/images/girls-images/cafe_coffee_portrait.png',
      'assets/images/girls-images/sunset_floral_portrait.png',
    ];
    if (_interestedIn == 'everyone') return [boys[0], girls[1], boys[2]];
    return switch (_gender) {
      'woman' => boys,
      'man' => girls,
      _ => [boys[0], girls[1], boys[2]],
    };
  }

  Widget _introPortrait(String image, double angle) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 130,
      height: 170,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    ),
  );

  Widget _introBody() => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 260,
            width: 300,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 5,
                  top: 45,
                  child: _introPortrait(_introPortraits[0], -0.12),
                ),
                Positioned(
                  right: 5,
                  top: 35,
                  child: _introPortrait(_introPortraits[1], 0.12),
                ),
                Positioned(
                  top: 85,
                  child: _introPortrait(_introPortraits[2], -0.03),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Good chemistry starts with the little things.',
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: AppColors.textOnDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Answer a few quick questions to meet people who share your kind of energy.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ),
  );
}
