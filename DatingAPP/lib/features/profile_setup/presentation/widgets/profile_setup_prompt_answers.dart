part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupPromptAnswers on _ProfileSetupScreenState {
  /// Opens the answer popup for [prompt]. A prompt is only added once its
  /// answer is saved, so every selected prompt always has an answer.
  Future<void> _editPromptAnswer(String prompt) async {
    final selected = _draft.selectedPrompts.contains(prompt);
    if (!selected && _draft.selectedPrompts.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose up to 5 prompts.')));
      return;
    }
    final result = await showModalBottomSheet<_PromptAnswerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PromptAnswerSheet(
        prompt: prompt,
        initialAnswer: _draft.answers[prompt],
        canRemove: selected,
      ),
    );
    if (!mounted || result == null) return;
    _refresh(() {
      if (result.remove) {
        _draft.removePrompt(prompt);
      } else {
        _draft.selectedPrompts.add(prompt);
        _draft.answers[prompt] = result.answer;
      }
    });
  }

  Widget _answerPrompts() => Column(
    children: [
      if (_draft.selectedPrompts.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text(
            'Prompts are optional. Add one whenever you like.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      for (final prompt in _draft.selectedPrompts)
        Container(
          margin: const EdgeInsets.only(bottom: 11),
          decoration: _cardDecoration(),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _editPromptAnswer(prompt),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 11, 4, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prompt, style: AppTypography.label),
                        const SizedBox(height: 5),
                        Text(
                          _draft.answers[prompt] ?? '',
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
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
            ),
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
                    Text(
                      _draft.selectedPrompts.isEmpty
                          ? 'Add a prompt'
                          : 'Add another prompt',
                      style: AppTypography.label,
                    ),
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

typedef _PromptAnswerResult = ({bool remove, String answer});

class _PromptAnswerSheet extends StatefulWidget {
  const _PromptAnswerSheet({
    required this.prompt,
    required this.initialAnswer,
    required this.canRemove,
  });

  final String prompt;
  final String? initialAnswer;
  final bool canRemove;

  @override
  State<_PromptAnswerSheet> createState() => _PromptAnswerSheetState();
}

class _PromptAnswerSheetState extends State<_PromptAnswerSheet> {
  late final _answer = TextEditingController(text: widget.initialAnswer);

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: ValueListenableBuilder<TextEditingValue>(
      valueListenable: _answer,
      builder: (context, value, _) {
        final answer = value.text.trim();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.prompt, style: AppTypography.h3),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('prompt-answer-field'),
              controller: _answer,
              autofocus: true,
              maxLength: 150,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Your answer…'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('prompt-answer-save'),
              onPressed: answer.isEmpty
                  ? null
                  : () => Navigator.pop<_PromptAnswerResult>(context, (
                      remove: false,
                      answer: answer,
                    )),
              child: const Text('Save'),
            ),
            if (widget.canRemove)
              TextButton(
                onPressed: () => Navigator.pop<_PromptAnswerResult>(context, (
                  remove: true,
                  answer: '',
                )),
                child: const Text('Remove prompt'),
              ),
          ],
        );
      },
    ),
  );
}
