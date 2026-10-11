part of '../screens/onboarding_questions_screen.dart';

extension _OnboardingBasicsLayout on _OnboardingQuestionsScreenState {
  Widget _buildBasicsScreen() {
    final birthday = _step == 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.backgroundWarm],
              ),
            ),
          ),
          if (!birthday)
            Align(
              alignment: Alignment.topCenter,
              child: ClipPath(
                clipper: _BasicsHeaderClipper(),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        AppAssets.welcomeBackground,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: AppColors.darkBackground.withValues(alpha: 0.74),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 94,
              width: double.infinity,
              child: CustomPaint(painter: _BasicsBottomPainter(_step)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: AdaptiveFlowColumn(
                children: [
                  _basicsProgress(birthday),
                  SizedBox(height: birthday ? 24 : 46),
                  Container(
                    height: 48,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.peachSoft.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coral.withValues(alpha: 0.18),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(_stepIcon, size: 25, color: AppColors.forest),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    OnboardingQuestionCopy.titles[_step],
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    OnboardingQuestionCopy.subtitle(_step, 0),
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: birthday
                        ? _basicsBirthdayPicker()
                        : _basicsChoices(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: FloatingActionButton(
                        heroTag: 'basics-next',
                        onPressed: _busy || !_canContinue ? null : _continue,
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        tooltip: 'Continue',
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicsProgress(bool birthday) => Row(
    children: [
      IconButton(
        onPressed: _back,
        tooltip: 'Back',
        icon: Icon(
          Icons.arrow_back_rounded,
          color: birthday ? AppColors.forestDark : Colors.white,
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _step == 10
                ? (_step - _OnboardingQuestionsScreenState._basicsSteps + 1) /
                      _OnboardingQuestionsScreenState._vibeSteps
                : (_step + 1) / _OnboardingQuestionsScreenState._basicsSteps,
            minHeight: 4,
            backgroundColor: birthday ? AppColors.border : Colors.white30,
            valueColor: AlwaysStoppedAnimation(
              birthday ? AppColors.forestDark : AppColors.peach,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        _step == 10
            ? '${_step - _OnboardingQuestionsScreenState._basicsSteps + 1}/${_OnboardingQuestionsScreenState._vibeSteps}'
            : '${_step + 1}/${_OnboardingQuestionsScreenState._basicsSteps}',
        style: AppTypography.caption.copyWith(
          color: birthday ? AppColors.forestDark : Colors.white,
        ),
      ),
      if (_skipKey(_step) != null)
        TextButton(
          onPressed: _busy ? null : _skip,
          style: TextButton.styleFrom(
            foregroundColor: birthday ? AppColors.forest : Colors.white,
            overlayColor: Colors.transparent,
          ),
          child: const Text('Skip'),
        ),
    ],
  );

  Widget _basicsBirthdayPicker() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const ValueKey('onboarding-name'),
          initialValue: _name,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.givenName],
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'Enter your name',
            helperText: 'This is the name people will see on your profile.',
            helperMaxLines: 2,
            prefixIcon: Icon(Icons.person_outline_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _refresh(() => _name = value),
        ),
        const SizedBox(height: 20),
        Text('Date of birth', style: AppTypography.label),
        SizedBox(
          height: 245,
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.light),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _birthDate.isAfter(_maximumBirthDate)
                  ? _maximumBirthDate
                  : _birthDate,
              minimumDate: DateTime(1900),
              maximumDate: _maximumBirthDate,
              onDateTimeChanged: (value) => _refresh(() => _birthDate = value),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _basicsChoices() {
    final options = switch (_step) {
      1 => OnboardingQuestionOptions.genders,
      2 => OnboardingQuestionOptions.attractions,
      _ => OnboardingQuestionOptions.intentions,
    };
    final selected = switch (_step) {
      1 => _gender,
      2 => _interestedIn,
      _ => _intentions.firstOrNull,
    };
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final (value, label, _) = options[index];
        final isSelected = selected == value;
        return Material(
          color: AppColors.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onTap: _busy
                ? null
                : () => _refresh(() {
                    if (_step == 1) {
                      _gender = value;
                    } else if (_step == 2) {
                      _interestedIn = value;
                    } else {
                      _intentions
                        ..clear()
                        ..add(value);
                    }
                  }),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.forest : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? AppColors.forest
                        : AppColors.borderStrong,
                    size: 26,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
