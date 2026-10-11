import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';

class ProfilePhotoEditScreen extends StatefulWidget {
  const ProfilePhotoEditScreen({
    super.key,
    required this.controller,
    required this.photo,
  });
  final ProfileController controller;
  final MemberPhoto photo;
  @override
  State<ProfilePhotoEditScreen> createState() => _ProfilePhotoEditScreenState();
}

class _ProfilePhotoEditScreenState extends State<ProfilePhotoEditScreen> {
  final _capture = GlobalKey();
  final _transform = TransformationController();
  double _aspect = 1;
  int _rotation = 0;
  double _brightness = 0;
  bool _mono = false, _ready = false, _saving = false;
  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await profileAction(context, () async {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('Could not export this photo.');
      await widget.controller.replacePhoto(
        widget.photo.id,
        bytes.buffer.asUint8List(),
      );
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Photo',
    bottom: ProfileButton(
      label: 'Save photo',
      busy: _saving,
      onPressed: _ready ? _save : null,
    ),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pinch to zoom and drag to frame your photo',
          style: const TextStyle(color: profileTextSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: RepaintBoundary(
              key: _capture,
              child: AspectRatio(
                aspectRatio: _aspect,
                child: ClipRect(
                  child: ColoredBox(
                    color: Colors.black,
                    child: InteractiveViewer(
                      transformationController: _transform,
                      minScale: 1,
                      maxScale: 4,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          _mono
                              ? [
                                  .2126,
                                  .7152,
                                  .0722,
                                  0,
                                  _brightness,
                                  .2126,
                                  .7152,
                                  .0722,
                                  0,
                                  _brightness,
                                  .2126,
                                  .7152,
                                  .0722,
                                  0,
                                  _brightness,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]
                              : [
                                  1,
                                  0,
                                  0,
                                  0,
                                  _brightness,
                                  0,
                                  1,
                                  0,
                                  0,
                                  _brightness,
                                  0,
                                  0,
                                  1,
                                  0,
                                  _brightness,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ],
                        ),
                        child: RotatedBox(
                          quarterTurns: _rotation,
                          child: Image.network(
                            widget.photo.url,
                            fit: BoxFit.cover,
                            frameBuilder: (_, child, frame, sync) {
                              if ((frame != null || sync) && !_ready) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) setState(() => _ready = true);
                                });
                              }
                              return child;
                            },
                            errorBuilder: (_, _, _) => const Center(
                              child: Text(
                                'Could not load photo',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [(1.0, '1:1'), (4 / 5, '4:5'), (16 / 9, '16:9')]
              .map(
                (r) => ChoiceChip(
                  label: Text(r.$2),
                  selected: _aspect == r.$1,
                  onSelected: (_) => setState(() {
                    _aspect = r.$1;
                    _transform.value = Matrix4.identity();
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _mono = !_mono),
              icon: const Icon(Icons.filter_b_and_w),
              label: Text(_mono ? 'Black & white' : 'Original'),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _rotation = (_rotation + 1) % 4),
              icon: const Icon(Icons.rotate_right),
              label: const Text('Rotate'),
            ),
          ],
        ),
        const ProfileSection('Brightness'),
        Slider(
          value: _brightness,
          min: -60,
          max: 60,
          onChanged: (v) => setState(() => _brightness = v),
        ),
        TextButton(
          onPressed: () => setState(() {
            _aspect = 1;
            _rotation = 0;
            _brightness = 0;
            _mono = false;
            _transform.value = Matrix4.identity();
          }),
          child: const Text('Reset edits'),
        ),
      ],
    ),
  );
}
