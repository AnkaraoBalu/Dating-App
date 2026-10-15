part of '../screens/profile_edit_screen.dart';

// Editors for prompts and for interests, music and era.
extension _ProfileEditPromptsInterestsSheets on _ProfileEditScreenState {
  Future<void> _editPrompts(BuildContext context, MemberProfile profile) async {
    final prompts = profile.prompts
        .map((prompt) => _PromptDraft(prompt['question']!, prompt['answer']!))
        .toList();
    final formKey = GlobalKey<FormState>();
    try {
      await _showEditor(
        context,
        title: 'Conversation prompts',
        fields: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              children: [
                if (prompts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No prompts yet. Add one to give people an easy way to start a conversation.',
                        style: TextStyle(
                          color: profileTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                for (var index = 0; index < prompts.length; index++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Prompt ${index + 1}',
                          style: const TextStyle(
                            color: profileTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove prompt',
                        onPressed: () {
                          final removed = prompts.removeAt(index);
                          setSheetState(() {});
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            removed.dispose();
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: prompts[index].question,
                    maxLength: 120,
                    decoration: const InputDecoration(labelText: 'Question'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: prompts[index].answer,
                    maxLength: 150,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Your answer'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (prompts.length < 5)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        prompts.add(_PromptDraft('', ''));
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add a prompt'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        onSave: (sheetContext) async {
          if (!formKey.currentState!.validate()) return false;
          final values = prompts
              .map(
                (prompt) => {
                  'question': prompt.question.text.trim(),
                  'answer': prompt.answer.text.trim(),
                },
              )
              .toList();
          if (values.any(
            (prompt) =>
                prompt['question']!.isEmpty || prompt['answer']!.isEmpty,
          )) {
            profileNotice(
              sheetContext,
              'Add both a question and answer, or remove the prompt.',
            );
            return false;
          }
          if (values.map((prompt) => prompt['question']).toSet().length !=
              values.length) {
            profileNotice(
              sheetContext,
              'Each prompt needs a different question.',
            );
            return false;
          }
          return profileAction(
            sheetContext,
            () => _controller.savePrompts(values),
          );
        },
      );
    } finally {
      for (final prompt in prompts) {
        prompt.dispose();
      }
    }
  }

  Future<void> _editInterests(
    BuildContext context,
    MemberProfile profile,
  ) async {
    final selected = profile.interests.toSet();
    final genres = profile.values('musicGenres', fromOnboarding: true).toSet();
    final artists = profile
        .values('favoriteArtists', fromOnboarding: true)
        .toSet();
    final dealbreakers = profile
        .values('dealbreakers', fromOnboarding: true)
        .toSet();
    final vibe = profile.lifestyleChoices('vibeTypes').toSet();
    final friday = profile.lifestyleChoices('idealFridays').toSet();
    final era = profile.lifestyleChoices('currentEras').toSet();
    final options = OnboardingQuestionOptions.interests;
    final musicOptions = OnboardingQuestionOptions.musicGenres
        .map((option) => (option.$1, option.$2))
        .toList();
    final vibeOptions = OnboardingQuestionOptions.vibes
        .map((option) => (option.$1, option.$2))
        .toList();
    final fridayOptions = OnboardingQuestionOptions.idealFridays
        .map((option) => (option.$1, option.$2))
        .toList();
    final eraOptions = OnboardingQuestionOptions.currentEras
        .map((option) => (option.$1, option.$2))
        .toList();
    await _showEditor(
      context,
      title: 'Interests & lifestyle',
      fields: StatefulBuilder(
        builder: (context, setSheetState) {
          Widget chips(
            Iterable<(String, String)> choices,
            Set<String> values,
            ValueChanged<String> toggle, {
            int? limit,
          }) => Wrap(
            spacing: 7,
            runSpacing: 4,
            children: [
              for (final choice in choices)
                FilterChip(
                  label: Text(choice.$2),
                  selected: values.contains(choice.$1),
                  selectedColor: profileAccent,
                  backgroundColor: profileBackground,
                  labelStyle: TextStyle(
                    color: values.contains(choice.$1)
                        ? profileTextPrimary
                        : profileTextSecondary,
                  ),
                  onSelected: (value) {
                    if (value && limit != null && values.length >= limit) {
                      profileNotice(context, 'Choose up to $limit items.');
                      return;
                    }
                    setSheetState(() => toggle(choice.$1));
                  },
                ),
            ],
          );

          void toggleMusic(String value, bool isArtist, bool add) {
            const general = ['a_bit_of_everything', 'not_big_on_music'];
            final target = isArtist ? artists : genres;
            if (!add) {
              target.remove(value);
            } else if (!isArtist && general.contains(value)) {
              genres
                ..clear()
                ..add(value);
              artists.clear();
            } else if (genres.length + artists.length >= 5) {
              profileNotice(context, 'Choose up to 5 artists and genres.');
              return;
            } else {
              genres.removeAll(general);
              target.add(value);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _editorLabel('Interests · ${selected.length}/5'),
              chips(
                options.map((option) => (option.$1, option.$2)),
                selected,
                (value) => selected.contains(value)
                    ? selected.remove(value)
                    : selected.add(value),
                limit: 5,
              ),
              const SizedBox(height: 18),
              _editorLabel('My vibe · ${vibe.length}/3'),
              chips(
                vibeOptions,
                vibe,
                (value) =>
                    vibe.contains(value) ? vibe.remove(value) : vibe.add(value),
                limit: 3,
              ),
              const SizedBox(height: 12),
              _editorLabel('My ideal Friday · ${friday.length}/3'),
              chips(
                fridayOptions,
                friday,
                (value) => friday.contains(value)
                    ? friday.remove(value)
                    : friday.add(value),
                limit: 3,
              ),
              const SizedBox(height: 12),
              _editorLabel('My current era · ${era.length}/2'),
              chips(
                eraOptions,
                era,
                (value) =>
                    era.contains(value) ? era.remove(value) : era.add(value),
                limit: 2,
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Music & artists'),
                subtitle: Text('${genres.length + artists.length}/5 selected'),
                children: [
                  chips(
                    musicOptions,
                    genres,
                    (value) =>
                        toggleMusic(value, false, !genres.contains(value)),
                    limit: 5,
                  ),
                  const SizedBox(height: 12),
                  _editorLabel('Favorite artists'),
                  chips(
                    OnboardingQuestionOptions.favoriteArtists.map(
                      (value) => (value, value),
                    ),
                    artists,
                    (value) =>
                        toggleMusic(value, true, !artists.contains(value)),
                    limit: 5,
                  ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('What matters to me'),
                subtitle: Text('${dealbreakers.length}/8 selected'),
                children: [
                  chips(
                    OnboardingQuestionOptions.dealbreakers.map(
                      (option) => (option.$1, option.$2),
                    ),
                    dealbreakers,
                    (value) {
                      if (dealbreakers.contains(value)) {
                        dealbreakers.remove(value);
                      } else if (value == 'no_hard_dealbreakers') {
                        dealbreakers
                          ..clear()
                          ..add(value);
                      } else {
                        dealbreakers
                          ..remove('no_hard_dealbreakers')
                          ..add(value);
                      }
                    },
                    limit: 8,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      onSave: (sheetContext) {
        if (selected.length > 5) {
          profileNotice(sheetContext, 'Choose up to 5 interests.');
          return Future.value(false);
        }
        return profileAction(sheetContext, () async {
          await _controller.updateOnboarding({
            'interests': selected.toList(),
            'vibeTypes': vibe.toList(),
            'idealFridays': friday.toList(),
            'currentEras': era.toList(),
            'musicGenres': genres.toList(),
            'favoriteArtists': artists.toList(),
            'dealbreakers': dealbreakers.toList(),
          });
        });
      },
    );
  }
}
