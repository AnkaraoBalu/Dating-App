import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

abstract final class LoginRoutes {
  static Future<T?> push<T>(BuildContext context, Widget screen) =>
      Navigator.of(context).push<T>(
        PageRouteBuilder<T>(
          pageBuilder: (_, animation, secondaryAnimation) => screen,
          transitionDuration: AppMotion.duration(context, AppMotion.navigation),
          reverseTransitionDuration: AppMotion.duration(
            context,
            AppMotion.navigation,
          ),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curved = animation.drive(CurveTween(curve: AppMotion.curve));
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: curved.drive(
                  Tween(begin: const Offset(0.05, 0), end: Offset.zero),
                ),
                child: child,
              ),
            );
          },
        ),
      );
}
