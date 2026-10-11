part of '../screens/profile_basics_screen.dart';

extension _ProfileBasicsSummarySections on _ProfileBasicsScreenState {
  Widget _summarySection() => Column(
    children: [
      _summaryRow(
        'Location',
        _valueOr('location', 'Not added'),
        Icons.location_on_outlined,
        1,
      ),
      _summaryRow(
        'Education',
        [
          _valueOr('education', 'Not added'),
          if ((_values['fieldOfStudy'] ?? '').isNotEmpty)
            _values['fieldOfStudy']!,
        ].join(' · '),
        Icons.school_outlined,
        2,
      ),
      _summaryRow(
        'Job title',
        _valueOr('jobTitle', 'Not added'),
        Icons.work_outline_rounded,
        4,
      ),
      _summaryRow(
        'Company',
        _valueOr('company', 'Not added'),
        Icons.business_outlined,
        5,
      ),
      _summaryRow(
        'Height',
        _heightTouched ? _heightLabel() : 'Not added',
        Icons.height_rounded,
        6,
      ),
      _summaryRow(
        'Zodiac',
        _valueOr('zodiac', 'Not added'),
        Icons.auto_awesome_outlined,
        7,
      ),
      _summaryRow(
        'Languages',
        _valueOr('languages', 'Not added'),
        Icons.language_rounded,
        8,
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _basicsCardDecoration(
          color: AppColors.peachSoft.withValues(alpha: .55),
        ),
        child: Text(
          'You can edit these details later from your profile.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

  Widget _summaryRow(String label, String value, IconData icon, int editStep) =>
      Container(
        margin: const EdgeInsets.only(bottom: 7),
        decoration: _basicsCardDecoration(),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: AppColors.forest, size: 21),
          title: Text(label, style: AppTypography.label),
          subtitle: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: TextButton(
            onPressed: () => _edit(editStep),
            child: const Text('Edit'),
          ),
        ),
      );

  Widget _completeSection() => Column(
    children: [
      const SizedBox(height: 24),
      Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          color: AppColors.coralSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.coralPressed,
          size: 62,
        ),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _basicsCardDecoration(),
        child: Column(
          children: [
            for (final item in [
              ('Location added', _values['location']?.isNotEmpty == true),
              ('Education added', _values['education']?.isNotEmpty == true),
              ('Job details added', _values['jobTitle']?.isNotEmpty == true),
              ('Height added', _heightTouched),
              ('Zodiac added', _values['zodiac']?.isNotEmpty == true),
              ('Languages added', _languages.isNotEmpty),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      item.$2
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: item.$2
                          ? AppColors.success
                          : AppColors.borderStrong,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.$1, style: AppTypography.body)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Your basics are ready. Next, let’s add the details that make your profile feel like you.',
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}
