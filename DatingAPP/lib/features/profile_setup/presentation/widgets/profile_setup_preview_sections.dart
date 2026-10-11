part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupPreviewSections on _ProfileSetupScreenState {
  Widget _preview() {
    final photoCount = _draft.photos.length;
    final promptEntries = _draft.selectedPrompts
        .map((question) => (question, (_draft.answers[question] ?? '').trim()))
        .where((entry) => entry.$2.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewHero(photoCount),
        const SizedBox(height: 16),
        _previewAboutCard(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Your photo stories', style: AppTypography.h2),
            ),
            if (photoCount > 0)
              Text(
                '${_previewPhotoIndex + 1} / $photoCount',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (photoCount > 0 && promptEntries.isNotEmpty)
          _photoPromptCarousel(photoCount, promptEntries)
        else
          _emptyPreviewCard(),
        if (photoCount > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoCount,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _previewPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 62,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _previewPhotoIndex == index
                          ? AppColors.coral
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: _photo(index),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Swipe through your photos to preview each prompt.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewAboutCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.coral,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('A little about me', style: AppTypography.label),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          _bio.text.trim().isEmpty
              ? 'Your bio will appear here.'
              : _bio.text.trim(),
          style: AppTypography.body.copyWith(
            color: _bio.text.trim().isEmpty
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
        if ((_basicValues['languages'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _basicValues['languages']!
                .split(',')
                .map((language) => language.trim())
                .where((language) => language.isNotEmpty)
                .map(
                  (language) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.selection,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      language,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  Widget _photoPromptCarousel(int photoCount, List<(String, String)> prompts) =>
      SizedBox(
        height: 390,
        child: PageView.builder(
          itemCount: photoCount,
          controller: _previewPageController,
          onPageChanged: (index) => _refresh(() => _previewPhotoIndex = index),
          itemBuilder: (context, index) {
            final prompt = prompts[index % prompts.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _photo(index),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.35, 1],
                          colors: [Colors.transparent, Color(0xE9000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 18,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: .96),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x26000000), blurRadius: 12),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prompt.$1,
                              style: AppTypography.label.copyWith(
                                color: AppColors.coralPressed,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              prompt.$2,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${index + 1} of $photoCount',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _emptyPreviewCard() => Container(
    height: 220,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      'Your photo prompts will appear here.',
      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
    ),
  );
}
