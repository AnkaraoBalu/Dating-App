part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupPhotoSections on _ProfileSetupScreenState {
  Widget _photo(int index, {BoxFit fit = BoxFit.cover}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: index < _draft.photos.length
        ? Image.network(
            _draft.photos[index].url,
            fit: fit,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final expected = progress.expectedTotalBytes;
              return ColoredBox(
                color: AppColors.surface,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: expected == null
                          ? null
                          : progress.cumulativeBytesLoaded / expected,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint(
                '[ProfileSetup] Cloudinary image failed to load for photo ${_draft.photos[index].id}: $error',
              );
              return Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: const Tooltip(
                  message: 'Couldn’t load photo',
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                ),
              );
            },
          )
        : ColoredBox(
            color: AppColors.surface,
            child: Image.asset(
              _photoPlaceholders[index % 6],
              fit: fit,
              color: Colors.black.withValues(alpha: 0.35),
              colorBlendMode: BlendMode.darken,
            ),
          ),
  );

  Widget _emptyPhotoTile(int index) => InkWell(
    onTap: _saving ? null : _pickPhoto,
    borderRadius: BorderRadius.circular(12),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            _photoPlaceholders[index % 6],
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.38),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    ),
  );

  Widget _intro() => Column(
    children: [
      const SizedBox(height: 24),
      SizedBox(
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(angle: -0.13, child: _polaroid(0, 210, 260)),
            Positioned(
              right: 0,
              top: 80,
              child: Transform.rotate(
                angle: 0.12,
                child: _polaroid(2, 120, 165),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 12,
              child: Transform.rotate(
                angle: 0.09,
                child: _polaroid(3, 120, 135),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Photos, stories, and little details make a profile feel like you.',
        textAlign: TextAlign.center,
        style: AppTypography.body,
      ),
    ],
  );

  Widget _polaroid(int index, double width, double height) => Container(
    width: width,
    height: height,
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14)],
    ),
    // The intro is an illustration, not the user's gallery. Keep it on the
    // bundled gender-based examples even when saved Cloudinary photos exist.
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        _photoPlaceholders[index % _photoPlaceholders.length],
        fit: BoxFit.cover,
      ),
    ),
  );

  Widget _addPhotos() => Column(
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.77,
        ),
        itemBuilder: (_, index) => index < _draft.photos.length
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _photo(index),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.close, size: 14),
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _deletePhoto(_draft.photos[index].id),
                    ),
                  ),
                ],
              )
            : _emptyPhotoTile(index),
      ),
      const SizedBox(height: 24),
      _tipBox('Photo tips', [
        'Clear face photo',
        'Show your hobbies and lifestyle',
        'Add 4–6 photos for better matches',
      ]),
      const SizedBox(height: 12),
      Text(
        _saving
            ? _uploadTotal > 0
                  ? 'Uploading $_uploadCurrent of $_uploadTotal photos…'
                  : _activityLabel
            : 'Your photos are securely saved to your profile.',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _reorderPhotos() => Column(
    children: [
      Text(
        'Hold and drag a photo to change its position.',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _draft.photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.77,
        ),
        itemBuilder: (_, index) => DragTarget<int>(
          onAcceptWithDetails: (details) => _reorder(details.data, index),
          builder: (context, candidateData, rejectedData) => AnimatedScale(
            scale: candidateData.isNotEmpty ? 1.06 : 1,
            duration: const Duration(milliseconds: 150),
            child: LongPressDraggable<int>(
              data: index,
              maxSimultaneousDrags: _saving ? 0 : 1,
              hapticFeedbackOnStart: true,
              feedback: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(width: 100, height: 130, child: _photo(index)),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: _photo(index)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.97,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Stack(
                  key: ValueKey(_draft.photos[index].id),
                  fit: StackFit.expand,
                  children: [
                    _photo(index),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.background,
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
