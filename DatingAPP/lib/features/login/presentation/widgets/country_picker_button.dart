import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../data/phone_countries.dart';
import '../../models/phone_country.dart';

class CountryPickerButton extends StatelessWidget {
  const CountryPickerButton({
    super.key,
    required this.country,
    required this.enabled,
    required this.onSelected,
  });

  final PhoneCountry country;
  final bool enabled;
  final ValueChanged<PhoneCountry> onSelected;

  Future<void> _showPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final value in PhoneCountries.all)
            ListTile(
              title: Text(value.name),
              trailing: Text(value.dialCode),
              selected: value == country,
              onTap: () => Navigator.pop(context, value),
            ),
        ],
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: enabled ? () => _showPicker(context) : null,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(country.dialCode),
        const SizedBox(width: AppSpacing.xxs),
        const Icon(Icons.expand_more_rounded, size: 18),
      ],
    ),
  );
}
