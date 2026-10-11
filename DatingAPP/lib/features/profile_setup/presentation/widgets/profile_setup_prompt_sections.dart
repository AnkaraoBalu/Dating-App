part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupPromptSections on _ProfileSetupScreenState {
  Widget _promptCategories() => Column(
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 3,
        children: ProfileSetupOptions.promptFilters.map((filter) {
          final active = _draft.filter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: active,
            showCheckmark: false,
            selectedColor: AppColors.coral,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: active ? AppColors.coral : AppColors.border,
            ),
            labelStyle: AppTypography.caption.copyWith(
              color: active ? Colors.white : AppColors.textPrimary,
            ),
            onSelected: (_) => _refresh(() => _draft.filter = filter),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),
      for (final section in ProfileSetupOptions.sectionsForFilter(
        _draft.filter,
      ))
        _promptCategoryCard(section),
    ],
  );

  Widget _promptCategoryCard(String section) {
    final (icon, color) = switch (section) {
      'About Me' => (Icons.favorite_rounded, AppColors.coral),
      'Fun & Quirky' => (Icons.auto_awesome_rounded, AppColors.coral),
      'Lifestyle' => (Icons.local_cafe_rounded, AppColors.forest),
      'Relationships' => (Icons.favorite_border_rounded, AppColors.coral),
      'Values & Opinions' => (Icons.public_rounded, AppColors.forest),
      'Goals & Ambitions' => (Icons.work_outline_rounded, AppColors.forest),
      'Music, Movies & Culture' => (Icons.music_note_rounded, AppColors.forest),
      _ => (Icons.help_outline_rounded, AppColors.forest),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: _cardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _refresh(() {
          _draft.selectedSection = section;
          _step = 4;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section, style: AppTypography.label),
                    Text(
                      ProfileSetupOptions.promptSectionDescriptions[section] ??
                          '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${ProfileSetupOptions.promptSections[section]?.length ?? 0} prompts',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickPrompts() {
    final sections = _draft.selectedSection == null
        ? ProfileSetupOptions.sectionsForFilter(_draft.filter)
        : [_draft.selectedSection!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '${_draft.selectedPrompts.length}/5 selected',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (sections.length == 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _refresh(() {
                _draft.selectedSection = null;
                _draft.filter = 'All';
              }),
              child: const Text('Browse all categories'),
            ),
          ),
        for (final section in sections) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: Text(section, style: AppTypography.h3)),
              TextButton(
                onPressed: () => _refresh(() {
                  _draft.expandedSection = _draft.expandedSection == section
                      ? null
                      : section;
                }),
                child: Text(
                  _draft.expandedSection == section ? 'Show less' : 'Show all',
                ),
              ),
            ],
          ),
          for (final prompt
              in ProfileSetupOptions.promptSections[section]!.take(
                _draft.expandedSection == section ? 100 : 3,
              ))
            _pickPromptRow(prompt),
        ],
      ],
    );
  }

  Widget _pickPromptRow(String prompt) {
    final selected = _draft.selectedPrompts.contains(prompt);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: _cardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (!selected && _draft.selectedPrompts.length >= 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Choose up to 5 prompts.')),
            );
            return;
          }
          _refresh(() {
            if (selected) {
              _draft.removePrompt(prompt);
            } else {
              _draft.selectedPrompts.add(prompt);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              Expanded(child: Text(prompt, style: AppTypography.body)),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 24,
                color: selected ? AppColors.coral : AppColors.borderStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
