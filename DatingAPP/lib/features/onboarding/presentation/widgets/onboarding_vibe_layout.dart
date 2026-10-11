part of '../screens/onboarding_questions_screen.dart';

extension _OnboardingVibeLayout on _OnboardingQuestionsScreenState {
  Widget _buildVibeScreen() => Scaffold(
    backgroundColor: AppColors.darkBackground,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.34,
          child: Image.asset(AppAssets.welcomeBackground, fit: BoxFit.cover),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xD8081714), Color(0xB6081714), Color(0xEA081714)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: AdaptiveFlowColumn(
              children: [
                _vibeProgress(),
                const SizedBox(height: 18),
                Text(
                  OnboardingQuestionCopy.titles[_step],
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.textOnDark,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  OnboardingQuestionCopy.subtitle(
                    _step,
                    _selectedInterests.length,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.82),
                  ),
                ),
                if (_step == 6 || _step == 7) ...[
                  const SizedBox(height: 14),
                  OnboardingSelectionCount(
                    dark: true,
                    count: _step == 6
                        ? _selectedInterests.length
                        : _selectedGenres.length + _selectedArtists.length,
                  ),
                ],
                const SizedBox(height: 20),
                Expanded(child: _questionBody()),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.peach,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _vibeButton(),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _vibeProgress() => Row(
    children: [
      IconButton(
        onPressed: _back,
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textOnDark),
      ),
      Text(
        '${_step - _OnboardingQuestionsScreenState._basicsSteps + 1}/${_OnboardingQuestionsScreenState._vibeSteps}',
        style: AppTypography.caption.copyWith(color: AppColors.textOnDark),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value:
                (_step - _OnboardingQuestionsScreenState._basicsSteps + 1) /
                _OnboardingQuestionsScreenState._vibeSteps,
            minHeight: 5,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation(AppColors.coral),
          ),
        ),
      ),
      const SizedBox(width: 8),
      if (_skipKey(_step) != null)
        TextButton(
          onPressed: _busy ? null : _skip,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            overlayColor: Colors.transparent,
          ),
          child: const Text('Skip'),
        ),
    ],
  );

  Widget _vibeButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.coral, AppColors.peach],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextButton(
        onPressed: _busy || !_canContinue ? null : _continue,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forestDeep,
          overlayColor: Colors.transparent,
          disabledForegroundColor: AppColors.forestDeep.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      _buttonLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        color: AppColors.forestDeep,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ),
      ),
    ),
  );

  IconData get _stepIcon => switch (_step) {
    0 => Icons.cake_outlined,
    1 => Icons.face_3_outlined,
    2 => Icons.favorite_border_rounded,
    3 => Icons.auto_awesome_outlined,
    4 => Icons.waving_hand_outlined,
    5 => Icons.nightlife_rounded,
    6 => Icons.interests_outlined,
    7 => Icons.music_note_rounded,
    8 => Icons.auto_awesome_outlined,
    9 => Icons.shield_outlined,
    10 => Icons.favorite_outline_rounded,
    11 => Icons.location_on_outlined,
    _ => Icons.check_circle_outline_rounded,
  };

  String get _buttonLabel => OnboardingQuestionCopy.buttonLabel(_step);

  Widget _questionBody() => switch (_step) {
    3 => _introBody(),
    4 => _vibeChoice(),
    5 => _fridayChoice(),
    6 => _multiChoice(
      OnboardingQuestionOptions.interests,
      _selectedInterests,
      (value) => _refresh(() => _toggleInterest(value)),
    ),
    7 => _musicChoice(),
    8 => _eraChoice(),
    9 => _dealbreakerChoice(),
    10 => _singleChoice(
      OnboardingQuestionOptions.intentions,
      _intentions.firstOrNull,
      (value) => _refresh(
        () => _intentions
          ..clear()
          ..add(value),
      ),
    ),
    11 => _locationPreferences(),
    _ => _summaryBody(),
  };
}
