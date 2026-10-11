import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/profile_widgets.dart';

part '../widgets/guided_selfie_sections.dart';

class GuidedSelfieCaptureScreen extends StatefulWidget {
  const GuidedSelfieCaptureScreen({super.key});

  @override
  State<GuidedSelfieCaptureScreen> createState() =>
      _GuidedSelfieCaptureScreenState();
}

class _GuidedSelfieCaptureScreenState extends State<GuidedSelfieCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  final List<XFile> _photos = [];
  int _step = 0;
  bool _initializing = true;
  bool _takingPhoto = false;
  bool _reviewingPhoto = false;
  bool _complete = false;
  String? _cameraError;

  bool get _reviewing => _reviewingPhoto;

  void _refresh(VoidCallback mutation) => setState(mutation);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed && !_complete) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _camera != null) return;
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    CameraController? candidate;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NoCamera',
          'No camera is available on this device.',
        );
      }
      final front = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      candidate = CameraController(
        front.isNotEmpty ? front.first : cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await candidate.initialize();
      if (!mounted) {
        await candidate.dispose();
        return;
      }
      setState(() {
        _camera = candidate;
        _initializing = false;
      });
    } on CameraException catch (error) {
      await candidate?.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError =
            error.code == 'CameraAccessDenied' ||
                error.code == 'CameraAccessDeniedWithoutPrompt'
            ? 'Camera permission is needed to take your guided selfies.'
            : 'The camera could not be started. Check camera access and try again.';
      });
    } catch (_) {
      await candidate?.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError =
            'The camera could not be started. Check camera access and try again.';
      });
    }
  }

  Future<void> _releaseCamera() async {
    final camera = _camera;
    _camera = null;
    if (camera != null) await camera.dispose();
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _takingPhoto) return;
    setState(() => _takingPhoto = true);
    try {
      final photo = await camera.takePicture();
      if (!mounted) {
        await File(photo.path).delete().catchError((_) => File(photo.path));
        return;
      }
      setState(() {
        _photos.add(photo);
        _takingPhoto = false;
        _reviewingPhoto = true;
      });
    } on CameraException {
      if (mounted) {
        setState(() => _takingPhoto = false);
        _showMessage('Could not take that photo. Please try again.');
      }
    }
  }

  Future<void> _retake() async {
    if (_photos.isEmpty) return;
    final photo = _photos.removeLast();
    await File(photo.path).delete().catchError((_) => File(photo.path));
    if (mounted) {
      setState(() => _reviewingPhoto = false);
    }
    if (_camera == null) await _initializeCamera();
  }

  Future<void> _finish() async {
    for (final photo in _photos) {
      await File(photo.path).delete().catchError((_) => File(photo.path));
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final camera = _camera;
    _camera = null;
    if (camera != null) camera.dispose();
    for (final photo in _photos) {
      File(photo.path).delete().catchError((_) => File(photo.path));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF08090B);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: background,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _complete ? _buildComplete() : _buildCapture(),
          ),
        ),
      ),
    );
  }

  Widget _buildCapture() {
    final currentPhoto = _reviewing ? _photos[_step] : null;
    return Column(
      key: ValueKey('capture-$_step-$_reviewing'),
      children: [
        _topBar('SELFIE ${_step + 1} OF 2'),
        const SizedBox(height: 14),
        Text(
          _step == 0
              ? 'Look straight at the camera'
              : 'Turn your face slightly',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 7),
        Text(
          _reviewing
              ? 'Check the framing, then continue.'
              : 'Use bright, even light and keep your face clear.',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (currentPhoto != null)
                    Image.file(File(currentPhoto.path), fit: BoxFit.cover)
                  else if (_camera?.value.isInitialized == true)
                    _preview(_camera!)
                  else
                    Container(
                      color: const Color(0xFF17191D),
                      alignment: Alignment.center,
                      child: _cameraError == null
                          ? const CircularProgressIndicator(
                              color: profileAccent,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.no_photography_outlined,
                                    color: Colors.white70,
                                    size: 38,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _cameraError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _initializing
                                        ? null
                                        : _initializeCamera,
                                    child: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  if (!_reviewing && _camera?.value.isInitialized == true)
                    IgnorePointer(
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: 245,
                          height: 335,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .88),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(130),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Center your face inside the guide',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _progressDots(),
        const SizedBox(height: 18),
        if (_reviewing)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retake,
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      setState(() {
                        if (_step == 0) {
                          _step = 1;
                          _reviewingPhoto = false;
                        } else {
                          _complete = true;
                        }
                      });
                      if (_complete) await _releaseCamera();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: profileAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_step == 0 ? 'Continue' : 'Review selfies'),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 68,
              child: IconButton(
                onPressed: _camera?.value.isInitialized == true && !_takingPhoto
                    ? _takePhoto
                    : null,
                icon: _takingPhoto
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: profileAccent,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                        ),
                      ),
                iconSize: 62,
                tooltip: 'Take selfie',
              ),
            ),
          ),
      ],
    );
  }
}
