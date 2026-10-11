part of '../screens/onboarding_questions_screen.dart';

extension _OnboardingSummarySection on _OnboardingQuestionsScreenState {
  Widget _summaryBody() => ListView(
    children: [
      _summaryRow('Name', _name.trim(), 0),
      _summaryRow('Birthday', _birthDateLabel, 0),
      _summaryRow('Gender', _labelFor(_gender), 1),
      _summaryRow('Interested in', _labelFor(_interestedIn), 2),
      _summaryRow('Energy', _labelFor(_vibeType), 4),
      _summaryRow('Ideal Friday', _labelFor(_idealFriday), 5),
      _summaryRow('Interests', _selectedInterests.map(_labelFor).join(', '), 6),
      _summaryRow('Music', _musicSummary, 7),
      _summaryRow('Current era', _labelFor(_currentEra), 8),
      _summaryRow(
        'Deal-breakers',
        _dealbreakers.isEmpty
            ? 'None selected'
            : _dealbreakers.map(_labelFor).join(', '),
        9,
      ),
      _summaryRow(
        'Dating intentions',
        _intentions.map(_labelFor).join(', '),
        10,
      ),
      _summaryRow(
        'Location',
        'Within $_preferredDistanceKm km${_onlyShowPeopleNearby ? ' · nearby only' : ''}',
        11,
      ),
    ],
  );

  Widget _summaryRow(String title, String value, int section) => InkWell(
    onTap: () => _refresh(() {
      _editingSummary = true;
      _step = section;
    }),
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _skippedQuestions.contains(_skipKey(section))
                      ? 'Skipped'
                      : value.isEmpty
                      ? 'Not set'
                      : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label,
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColors.forest, size: 19),
        ],
      ),
    ),
  );

  String get _birthDateLabel =>
      '${_birthDate.day.toString().padLeft(2, '0')}/'
      '${_birthDate.month.toString().padLeft(2, '0')}/${_birthDate.year}';

  String get _musicSummary {
    final choices = [..._selectedGenres.map(_labelFor), ..._selectedArtists];
    return choices.join(', ');
  }

  String _labelFor(String? value) => OnboardingQuestionOptions.labelFor(value);
}
