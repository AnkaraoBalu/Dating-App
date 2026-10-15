import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../../core/theme/theme.dart';

/// Makes sure the microphone is allowed before a call starts or is answered.
///
/// Android always words its microphone dialog as "record audio", so the first
/// time we explain why first. Returns true when the microphone can be used.
Future<bool> ensureCallMicrophone(
  BuildContext context, {
  required String peerName,
}) async {
  final recorder = AudioRecorder();
  try {
    if (await recorder.hasPermission(request: false)) return true;
    if (!context.mounted) return false;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.coralSoft,
              child: Icon(Icons.mic_rounded, color: AppColors.coral, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Turn on your microphone',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'So $peerName can hear you. Just2 only uses the microphone while '
              'you are on a call, and calls are never recorded.\n\n'
              'Android will ask to allow "record audio" next.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('call-mic-continue'),
              onPressed: () => Navigator.pop(sheetContext, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
    if (proceed != true) return false;
    final granted = await recorder.hasPermission();
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone is off. Allow it for Just2 in your phone Settings to make calls.',
          ),
        ),
      );
    }
    return granted;
  } finally {
    await recorder.dispose();
  }
}
