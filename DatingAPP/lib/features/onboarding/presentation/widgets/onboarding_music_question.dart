import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../data/onboarding_question_options.dart';
import 'onboarding_choice_tile.dart';

class OnboardingMusicQuestion extends StatefulWidget {
  const OnboardingMusicQuestion({
    super.key,
    required this.genres,
    required this.artists,
    required this.enabled,
    required this.onChanged,
    this.dark = false,
  });

  final Set<String> genres;
  final Set<String> artists;
  final bool enabled;
  final bool dark;
  final ValueChanged<({Set<String> genres, Set<String> artists})> onChanged;

  @override
  State<OnboardingMusicQuestion> createState() =>
      _OnboardingMusicQuestionState();
}

class _OnboardingMusicQuestionState extends State<OnboardingMusicQuestion> {
  String _query = '';

  void _toggleArtist(String artist) {
    final artists = {...widget.artists};
    final genres = {...widget.genres};
    if (!artists.remove(artist)) {
      if (artists.length + genres.length >= 5) return;
      genres
        ..remove('a_bit_of_everything')
        ..remove('not_big_on_music');
      artists.add(artist);
    }
    widget.onChanged((genres: genres, artists: artists));
  }

  void _toggleGenre(String genre) {
    final genres = {...widget.genres};
    final artists = {...widget.artists};
    if (!genres.remove(genre)) {
      if (artists.length + genres.length >= 5) return;
      if (genre == 'a_bit_of_everything' || genre == 'not_big_on_music') {
        genres.clear();
        artists.clear();
      } else {
        genres
          ..remove('a_bit_of_everything')
          ..remove('not_big_on_music');
      }
      genres.add(genre);
    }
    widget.onChanged((genres: genres, artists: artists));
  }

  void _addArtist(String input) {
    final artist = input.trim();
    if (artist.isEmpty ||
        widget.artists.any(
          (selected) => selected.toLowerCase() == artist.toLowerCase(),
        )) {
      return;
    }
    _toggleArtist(artist);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final genres = OnboardingQuestionOptions.musicGenres
        .where(
          (option) => query.isEmpty || option.$2.toLowerCase().contains(query),
        )
        .toList();
    final artists = OnboardingQuestionOptions.favoriteArtists
        .where(
          (artist) => query.isEmpty || artist.toLowerCase().contains(query),
        )
        .toList();

    return Column(
      children: [
        TextField(
          enabled: widget.enabled,
          style: TextStyle(
            color: widget.dark ? Colors.white : AppColors.textPrimary,
          ),
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: _addArtist,
          maxLength: 80,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Search artists or genres…',
            hintStyle: TextStyle(
              color: widget.dark ? Colors.white70 : AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: widget.dark ? Colors.white : AppColors.forest,
            ),
            suffixIcon: IconButton(
              tooltip: 'Add artist',
              onPressed: widget.enabled ? () => _addArtist(_query) : null,
              icon: Icon(
                Icons.add_rounded,
                color: widget.dark ? Colors.white : AppColors.forest,
              ),
            ),
            filled: true,
            fillColor: widget.dark
                ? AppColors.darkSurface.withValues(alpha: 0.8)
                : AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: BorderSide(
                color: widget.dark ? Colors.white54 : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: BorderSide(
                color: widget.dark ? Colors.white54 : AppColors.border,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView(
            children: [
              Text(
                'Artists',
                style: AppTypography.label.copyWith(
                  color: widget.dark ? Colors.white : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: artists.map((artist) {
                  final selected = widget.artists.contains(artist);
                  return FilterChip(
                    label: Text(artist),
                    selected: selected,
                    onSelected: widget.enabled
                        ? (_) => _toggleArtist(artist)
                        : null,
                    selectedColor: widget.dark
                        ? AppColors.darkSurface2
                        : AppColors.peachSoft,
                    checkmarkColor: AppColors.forest,
                    backgroundColor: widget.dark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    labelStyle: TextStyle(
                      color: widget.dark ? Colors.white : AppColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.peach
                          : widget.dark
                          ? Colors.white54
                          : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Genres',
                style: AppTypography.label.copyWith(
                  color: widget.dark ? Colors.white : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 520 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * AppSpacing.sm) /
                      columns;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: genres.map((option) {
                      final (value, label, icon) = option;
                      final selected = widget.genres.contains(value);
                      final canAdd =
                          widget.artists.length + widget.genres.length < 5;
                      return SizedBox(
                        width: width,
                        height: 54,
                        child: OnboardingOptionChip(
                          label: label,
                          icon: icon,
                          selected: selected,
                          dark: widget.dark,
                          enabled: widget.enabled && (selected || canAdd),
                          onTap: () => _toggleGenre(value),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
