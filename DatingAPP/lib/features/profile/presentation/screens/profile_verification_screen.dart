import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/profile_controller.dart';
import '../widgets/profile_widgets.dart';

class ProfileVerificationScreen extends StatefulWidget {
  const ProfileVerificationScreen({super.key, required this.controller});
  final ProfileController controller;

  @override
  State<ProfileVerificationScreen> createState() =>
      _ProfileVerificationScreenState();
}

class _ProfileVerificationScreenState extends State<ProfileVerificationScreen> {
  static const _faceTecChannel = MethodChannel('matchify/facetec');
  bool _openingCamera = false;

  String get _status =>
      widget.controller.profile?.text('verificationStatus') ?? 'not_started';

  Future<void> _startCapture() async {
    if (_openingCamera) return;
    final consent = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: profileSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Before you start',
                style: TextStyle(
                  color: profileTextPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'FaceTec will open its live selfie check and send the encrypted '
                'session directly to FaceTec’s developer Testing API. This is '
                'for development only. Matchify has not connected a verification '
                'backend yet, so this will not submit a result or add a badge.',
                style: TextStyle(color: profileTextSecondary, height: 1.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: profileAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open camera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (consent != true || !mounted) return;
    setState(() => _openingCamera = true);
    try {
      final completed = await _faceTecChannel.invokeMethod<bool>(
        'startLiveness',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completed == true
                  ? 'FaceTec test session completed. No Matchify verification badge was changed.'
                  : 'FaceTec session was not completed.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'FaceTec could not start.')),
        );
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FaceTec is unavailable on this platform.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingCamera = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => ProfilePage(
      title: 'Verification',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _statusHeader,
          const SizedBox(height: 24),
          _status == 'verified'
              ? _verifiedCard
              : _status == 'pending'
              ? _pendingCard
              : _introCard,
          const SizedBox(height: 20),
          _stepRow(
            number: '1',
            title: 'Start a live face scan',
            detail: 'FaceTec opens the camera after you give permission.',
            icon: Icons.face_retouching_natural_rounded,
          ),
          _stepRow(
            number: '2',
            title: 'Follow FaceTec’s prompts',
            detail: 'Keep your face visible and follow the live capture guide.',
            icon: Icons.motion_photos_on_rounded,
          ),
          _stepRow(
            number: '3',
            title: 'Finish the developer test',
            detail:
                'A completed test session does not verify your Matchify profile.',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: profileSurfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: profileBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, color: profileAccent),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'A real verification check needs a secure liveness and '
                    'photo-matching service. Until one is connected, this '
                    'development integration sends the FaceTec scan to its Testing API. '
                    'No Matchify badge is granted by this test flow.',
                    style: TextStyle(
                      color: profileTextSecondary,
                      height: 1.45,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_status != 'verified')
            FilledButton.icon(
              onPressed: _openingCamera ? null : _startCapture,
              icon: _openingCamera
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.face_retouching_natural_rounded),
              label: Text(
                _openingCamera ? 'Opening FaceTec…' : 'Start FaceTec check',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: profileAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'A badge shows photo similarity only; it does not guarantee identity or safety.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: profileTextTertiary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget get _statusHeader => Container(
    width: 88,
    height: 88,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: profileAccent.withValues(alpha: .12),
      border: Border.all(color: profileAccent.withValues(alpha: .25)),
    ),
    child: Icon(
      _status == 'verified'
          ? Icons.verified_rounded
          : Icons.face_retouching_natural_rounded,
      size: 43,
      color: _status == 'verified' ? const Color(0xFF52A8FF) : profileAccent,
    ),
  );

  Widget get _introCard => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: profileSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: profileBorder),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show people your photos are really you',
          style: TextStyle(
            color: profileTextPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        SizedBox(height: 9),
        Text(
          'A quick, guided selfie check can help build confidence before you match.',
          style: TextStyle(color: profileTextSecondary, height: 1.45),
        ),
      ],
    ),
  );

  Widget get _pendingCard => _statusCard(
    icon: Icons.hourglass_top_rounded,
    title: 'Verification is under review',
    detail:
        'We’ll show the badge after a verification provider confirms the result.',
    color: const Color(0xFFFFC56D),
  );

  Widget get _verifiedCard => _statusCard(
    icon: Icons.verified_rounded,
    title: 'Your profile is verified',
    detail: 'Your profile has completed photo verification.',
    color: const Color(0xFF52A8FF),
  );

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .32)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                style: const TextStyle(
                  color: profileTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _stepRow({
    required String number,
    required String title,
    required String detail,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: profileSurface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: profileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: profileAccent.withValues(alpha: .13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: profileAccent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: profileTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: profileTextSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            number,
            style: const TextStyle(
              color: profileTextTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
