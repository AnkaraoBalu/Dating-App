import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../data/onboarding_question_copy.dart';
import '../../../profile_setup/presentation/screens/profile_setup_screen.dart';
import '../../../profile_setup/data/profile_setup_api.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({
    super.key,
    this.genderIdentity,
    this.profileApi,
  });

  final String? genderIdentity;
  final ProfileSetupApi? profileApi;

  void _createProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileSetupScreen(genderIdentity: genderIdentity, api: profileApi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkBackground,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.35,
          child: Image.asset(AppAssets.welcomeBackground, fit: BoxFit.cover),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xAA081714), Color(0xE6081714)],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.background, AppColors.backgroundWarm],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppColors.selection,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.forest,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    OnboardingQuestionCopy.completedTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(height: 1.2),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    OnboardingQuestionCopy.completedSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.asset(
                      AppAssets.welcomePersonality,
                      width: double.infinity,
                      height: 156,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: OnboardingQuestionCopy.createProfile,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _createProfile(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
