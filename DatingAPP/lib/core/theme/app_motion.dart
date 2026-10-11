import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 220);
  static const navigation = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 360);
  static const hero = Duration(milliseconds: 500);
  static const match = Duration(milliseconds: 1200);
  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}
