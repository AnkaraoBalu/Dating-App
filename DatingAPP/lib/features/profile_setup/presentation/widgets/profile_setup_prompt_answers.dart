part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupPromptAnswers on _ProfileSetupScreenState {
  Widget _answerPrompts() => Column(
    children: [
      for (final prompt in _draft.selectedPrompts)
        Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.fromLTRB(15, 11, 12, 6),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(prompt, style: AppTypography.label)),
                  IconButton(
                    tooltip: 'Remove prompt',
                    onPressed: () =>
                        _refresh(() => _draft.removePrompt(prompt)),
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              TextFormField(
                key: ValueKey(prompt),
                initialValue: _draft.answers[prompt],
                maxLength: 150,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Your answer…',
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => _draft.answers[prompt] = value,
              ),
            ],
          ),
        ),
      InkWell(
        onTap: () => _refresh(() {
          _draft.selectedSection = null;
          _draft.filter = 'All';
          _step = 4;
        }),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.borderStrong,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(Icons.add_rounded, color: AppColors.coral),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add another prompt', style: AppTypography.label),
                    Text(
                      'Show more sides of you',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✦  Tip',
              style: AppTypography.label.copyWith(
                color: AppColors.coralPressed,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Be specific and genuine\nAdd a bit of personality\nShort and interesting works best',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _promptPreview() => Column(
    children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _draft.photos.isNotEmpty
                  ? Image.network(
                      _draft.photos.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Image.asset(_photoPlaceholders[0], fit: BoxFit.cover),
                    )
                  : Image.asset(_photoPlaceholders[0], fit: BoxFit.cover),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Color(0xBB000000),
                      Color(0xE6000000),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 145, 13, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your profile',
                    style: AppTypography.h1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  for (final prompt in _draft.selectedPrompts)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(prompt, style: AppTypography.label),
                          const SizedBox(height: 5),
                          Text(
                            (_draft.answers[prompt] ?? '').trim().isEmpty
                                ? 'Your answer will appear here.'
                                : _draft.answers[prompt]!,
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _refresh(() => _step = 5),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Edit prompts',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
