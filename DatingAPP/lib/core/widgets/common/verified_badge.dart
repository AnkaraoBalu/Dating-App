import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});
  @override
  Widget build(BuildContext context) => const Tooltip(
    message: 'Verified profile',
    child: Icon(
      Icons.verified_rounded,
      color: AppColors.verified,
      size: AppSizes.metadataIcon,
      semanticLabel: 'Verified profile',
    ),
  );
}
