import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const display = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 42,
    height: 1.05,
    fontWeight: FontWeight.w400,
  );
  static const hero = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w400,
  );
  static const h1 = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w400,
  );
  static const h2 = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 25,
    height: 1.18,
    fontWeight: FontWeight.w400,
  );
  static const h3 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const bodyLarge = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const body = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodySmall = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
  static const label = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const button = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const caption = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
  // Welcome reference: editorial wordmark, quiet UI, handwritten tagline.
  static const welcomeBrand = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.8,
  );
  static const welcomeBody = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const welcomeHandwriting = TextStyle(
    fontFamily: 'Caveat',
    fontSize: 34,
    height: 0.95,
    fontWeight: FontWeight.w400,
  );
  static const welcomeButton = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const welcomeSignIn = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const textTheme = TextTheme(
    displayLarge: display,
    displayMedium: hero,
    displaySmall: h1,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleLarge: h3,
    titleMedium: title,
    titleSmall: label,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: label,
    labelSmall: caption,
  );
}
