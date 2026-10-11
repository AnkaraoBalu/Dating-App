part of '../screens/guided_selfie_capture_screen.dart';

// Completion summary, camera preview, top bar and progress dots.
extension _GuidedSelfieSections on _GuidedSelfieCaptureScreenState {
  Future<void> _retakePhotoAt(int index) async {
    final removed = _photos.skip(index).toList();
    _photos.removeRange(index, _photos.length);
    for (final photo in removed) {
      await File(photo.path).delete().catchError((_) => File(photo.path));
    }
    if (mounted) {
      _refresh(() {
        _step = index;
        _complete = false;
        _reviewingPhoto = false;
      });
    }
    if (_camera == null) await _initializeCamera();
  }

  Widget _buildComplete() => Column(
    key: const ValueKey('selfie-review'),
    children: [
      _topBar('REVIEW SELFIES'),
      const SizedBox(height: 22),
      const Text(
        'Looking good?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          'Review both photos. You can retake either one before leaving.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
      ),
      const SizedBox(height: 24),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 0 ? 8 : 0,
                    left: index == 1 ? 8 : 0,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(
                            File(_photos[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => _retakePhotoAt(index),
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: Text('Retake ${index + 1}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(24, 12, 24, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded, color: profileAccent, size: 19),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'These photos stay on this device and will be deleted when you finish. Verification is not submitted because a liveness and face-match provider is not connected yet.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _finish,
            style: FilledButton.styleFrom(
              backgroundColor: profileAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard and finish'),
          ),
        ),
      ),
    ],
  );

  Widget _preview(CameraController camera) {
    final size = camera.value.previewSize;
    if (size == null) return CameraPreview(camera);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(camera),
        ),
      ),
    );
  }

  Widget _topBar(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: _finish,
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );

  Widget _progressDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      2,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: index == _step ? 24 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: index <= _step ? profileAccent : Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
