import 'package:flutter/material.dart';
import 'interest_chip.dart';

class VibeChip extends InterestChip {
  const VibeChip({
    super.key,
    required super.label,
    super.icon = Icons.favorite_border_rounded,
  }) : super(romantic: true);
}
