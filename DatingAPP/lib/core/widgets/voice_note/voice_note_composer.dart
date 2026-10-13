import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../theme/theme.dart';

/// A recorded voice message clip, ready to upload.
class VoiceNote {
  const VoiceNote({required this.path, required this.duration});

  final String path;
  final Duration duration;
}

const voiceNoteMaxDuration = Duration(minutes: 2);
const _voiceNoteMinDuration = Duration(seconds: 1);

/// Wraps a chat composer row with voice messages. While the text field is
/// empty the action button is a mic; tapping it records until the member
/// sends or discards the clip. With text, the action button sends the text.
class VoiceNoteComposer extends StatefulWidget {
  const VoiceNoteComposer({
    super.key,
    required this.textController,
    required this.onSendText,
    required this.onSendVoice,
    required this.builder,
    this.sendButtonSize,
  });

  final TextEditingController textController;
  final VoidCallback onSendText;
  final ValueChanged<VoiceNote> onSendVoice;

  /// Builds the normal composer row around [actionButton] (send or mic).
  final Widget Function(BuildContext context, Widget actionButton) builder;
  final double? sendButtonSize;

  @override
  State<VoiceNoteComposer> createState() => _VoiceNoteComposerState();
}

class _VoiceNoteComposerState extends State<VoiceNoteComposer> {
  final _recorder = AudioRecorder();
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  String? _path;
  bool _starting = false;

  bool get _recording => _startedAt != null;

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_discardRecording());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || _recording) return;
    _starting = true;
    try {
      if (!await _recorder.hasPermission()) {
        _notice('Allow microphone access in Settings to send voice messages.');
        return;
      }
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) {
        await _recorder.cancel();
        return;
      }
      setState(() {
        _path = path;
        _startedAt = DateTime.now();
        _elapsed = Duration.zero;
      });
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final startedAt = _startedAt;
        if (startedAt == null || !mounted) return;
        setState(() => _elapsed = DateTime.now().difference(startedAt));
        if (_elapsed >= voiceNoteMaxDuration) unawaited(_send());
      });
    } catch (_) {
      _notice('Could not start recording. Try again.');
    } finally {
      _starting = false;
    }
  }

  Future<void> _send() async {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _ticker?.cancel();
    final duration = DateTime.now().difference(startedAt);
    setState(() => _startedAt = null);
    String? path;
    try {
      path = await _recorder.stop() ?? _path;
    } catch (_) {
      path = null;
    }
    _path = null;
    if (path == null) {
      _notice('Could not save that recording. Try again.');
      return;
    }
    if (duration < _voiceNoteMinDuration) {
      unawaited(_deleteFile(path));
      _notice('Hold on a little longer to record a voice message.');
      return;
    }
    widget.onSendVoice(
      VoiceNote(
        path: path,
        duration: duration > voiceNoteMaxDuration
            ? voiceNoteMaxDuration
            : duration,
      ),
    );
  }

  Future<void> _discard() async {
    _ticker?.cancel();
    if (mounted) setState(() => _startedAt = null);
    await _discardRecording();
  }

  Future<void> _discardRecording() async {
    final path = _path;
    _path = null;
    try {
      await _recorder.cancel();
    } catch (_) {
      // Nothing was recording.
    }
    if (path != null) await _deleteFile(path);
  }

  Future<void> _deleteFile(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      // Temporary files are cleaned up by the OS eventually.
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_recording) return _recordingBar();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.textController,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return widget.builder(
          context,
          IconButton.filled(
            onPressed: hasText ? widget.onSendText : () => unawaited(_start()),
            tooltip: hasText ? 'Send' : 'Record a voice message',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              hasText ? Icons.send_rounded : Icons.mic_rounded,
              size: widget.sendButtonSize,
            ),
          ),
        );
      },
    );
  }

  Widget _recordingBar() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => unawaited(_discard()),
            tooltip: 'Discard',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 10),
                  Text(
                    formatVoiceDuration(_elapsed),
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recording…',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: () => unawaited(_send()),
            tooltip: 'Send voice message',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

/// `m:ss`, as shown on voice message bubbles and while recording.
String formatVoiceDuration(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .3, end: 1).animate(_controller),
    child: Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    ),
  );
}
