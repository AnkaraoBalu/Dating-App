import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon == null ? null : Icon(icon, size: AppSizes.chipIcon),
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
      ),
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
      chipAnimationStyle: ChipAnimationStyle(
        selectAnimation: AnimationStyle(
          duration: AppMotion.duration(context, AppMotion.normal),
        ),
      ),
    );
  }
}
