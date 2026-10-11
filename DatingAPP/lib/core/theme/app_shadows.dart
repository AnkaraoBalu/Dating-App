import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const love = [
    BoxShadow(color: Color(0x38FF6678), blurRadius: 18, offset: Offset(0, 8)),
  ];
  static BoxShadow get brand =>
      const BoxShadow(color: AppColors.softScrim, blurRadius: 8);
}
