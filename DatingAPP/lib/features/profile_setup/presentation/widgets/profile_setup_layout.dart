part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupLayout on _ProfileSetupScreenState {
  Widget _buildLayout(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      _refresh(() {
                        _loading = true;
                        _loadError = null;
                      });
                      _loadProfile();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          )
        : SafeArea(
            child: AdaptiveFlowColumn(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(child: _progress()),
                      if (_step == 0 || _step == 3)
                        TextButton(
                          onPressed: _step == 3
                              ? () => _refresh(() => _step = 7)
                              : () => Navigator.of(context).pop(),
                          child: const Text('Skip'),
                        )
                      else if (_step == 4 || _step == 5)
                        TextButton(
                          onPressed: () => _refresh(() => _step = 6),
                          child: const Text('Preview'),
                        )
                      else
                        const SizedBox(width: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        ProfileSetupCopy.titles[_step],
                        style: AppTypography.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ProfileSetupCopy.subtitles[_step],
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                    child: _body(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: Column(
                    children: [
                      if (_step == 9 || _step == 11)
                        TextButton(
                          onPressed: _step == 9
                              ? _next
                              : () => Navigator.of(context).pop(),
                          child: const Text('Maybe later'),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.coral, Color(0xFFFF4A6B)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TextButton(
                            key: const ValueKey('profile-setup-next'),
                            onPressed: _saving ? null : _next,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_saving && _uploadTotal > 0)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _uploadProgress.clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.22,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          switch (_step) {
                                            0 => 'Get started',
                                            6 => 'Save & Continue',
                                            8 => "Let's go",
                                            10 => 'Looks good',
                                            11 => 'Start verification',
                                            _ =>
                                              _saving && _uploadTotal > 0
                                                  ? 'Uploading $_uploadCurrent/$_uploadTotal · ${(_uploadProgress * 100).round()}%'
                                                  : _saving
                                                  ? _activityLabel
                                                  : 'Continue',
                                          },
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.button.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (_saving && _uploadTotal == 0) ...[
                                        const SizedBox(width: 10),
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ] else if (_saving) ...[
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 17,
                                          height: 17,
                                          child: CircularProgressIndicator(
                                            value: _uploadTotal > 0
                                                ? _uploadProgress
                                                : null,
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 19,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (_saving && _uploadTotal == 0)
                                  const Positioned(
                                    left: 26,
                                    right: 26,
                                    bottom: 0,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(3),
                                      ),
                                      child: LinearProgressIndicator(
                                        minHeight: 3,
                                        backgroundColor: Colors.transparent,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
  );

  Widget _progress() => Row(
    children: List.generate(4, (index) {
      final fill = ((_step + 1) / ProfileSetupCopy.titles.length * 4 - index)
          .clamp(0.0, 1.0);
      return Expanded(
        child: Container(
          height: 4,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: AppColors.borderStrong,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: fill,
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      );
    }),
  );

  Widget _body() => switch (_step) {
    0 => _intro(),
    1 => _addPhotos(),
    2 => _reorderPhotos(),
    3 => _promptCategories(),
    4 => _pickPrompts(),
    5 => _answerPrompts(),
    6 => _promptPreview(),
    7 => _bioBody(),
    8 => _basicsIntro(),
    9 => _music(),
    10 => _preview(),
    _ => _verify(),
  };
}
