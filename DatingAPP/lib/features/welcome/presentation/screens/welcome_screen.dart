import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';
import 'welcome_carousel_screen.dart';
import '../../../login/presentation/navigation/login_routes.dart';
import '../../../login/presentation/screens/login_screen.dart';
import '../widgets/welcome_actions.dart';
import '../widgets/welcome_brand.dart';
import '../widgets/welcome_illustration.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.onGetStarted, this.onSignIn});
  final VoidCallback? onGetStarted;
  final VoidCallback? onSignIn;

  void _openCarousel(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const WelcomeCarouselScreen(),
        transitionDuration: reduceMotion ? Duration.zero : AppMotion.navigation,
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : AppMotion.navigation,
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: animation.drive(CurveTween(curve: AppMotion.curve)),
              child: child,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.darkBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const WelcomeIllustration(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.contentMaxWidth,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.xl,
                              AppSpacing.lg,
                              AppSpacing.xs,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(flex: 3),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: AppMotion.duration(
                                    context,
                                    AppMotion.hero,
                                  ),
                                  curve: AppMotion.curve,
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        (1 - value) * AppSpacing.md,
                                      ),
                                      child: child,
                                    ),
                                  ),
                                  child: const WelcomeBrand(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                const Spacer(flex: 2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    AppConstants.welcomeMessage,
                                    textAlign: TextAlign.right,
                                    style: AppTypography.welcomeHandwriting
                                        .copyWith(color: AppColors.textOnDark),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                WelcomeActions(
                                  onGetStarted:
                                      onGetStarted ??
                                      () => _openCarousel(context),
                                  onSignIn:
                                      onSignIn ??
                                      () => LoginRoutes.push<void>(
                                        context,
                                        const LoginScreen(),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
