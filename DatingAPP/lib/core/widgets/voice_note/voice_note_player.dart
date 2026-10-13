import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../theme/theme.dart';
import 'voice_note_composer.dart';

/// Play/pause, progress and length for a voice message bubble. The audio
/// player is created on first play, and starting one voice message pauses
/// any other that is playing.
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.duration,
    this.url,
    this.localPath,
    this.onAccent = false,
  });

  final String? url;
  final String? localPath;
  final Duration duration;

  /// True on the sender's coral bubble, where controls are drawn in white.
  final bool onAccent;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  static _VoiceNotePlayerState? _playing;

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _states;
  StreamSubscription<Duration>? _positions;
  Duration _position = Duration.zero;
  Duration? _loadedDuration;
  bool _isPlaying = false;
  bool _loading = false;
  bool _failed = false;
  bool _toggling = false;

  Duration get _duration {
    final loaded = _loadedDuration;
    return loaded != null && loaded > Duration.zero ? loaded : widget.duration;
  }

  @override
  void didUpdateWidget(VoiceNotePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A sent message swaps its local file for the uploaded URL; keep playing
    // the local copy rather than reloading mid-playback.
    if ((oldWidget.url != widget.url ||
            oldWidget.localPath != widget.localPath) &&
        _player != null &&
        !_isPlaying) {
      unawaited(_release());
    }
  }

  @override
  void dispose() {
    if (_playing == this) _playing = null;
    unawaited(_release());
    super.dispose();
  }

  Future<void> _release() async {
    final player = _player;
    _player = null;
    _loadedDuration = null;
    final states = _states;
    final positions = _positions;
    _states = null;
    _positions = null;
    _loading = false;
    _isPlaying = false;
    _position = Duration.zero;
    await states?.cancel();
    await positions?.cancel();
    await player?.dispose();
  }

  Future<void> _toggle() async {
    if (_toggling || !mounted) return;
    _toggling = true;
    try {
      if (_isPlaying) {
        await _player?.pause();
        return;
      }
      final previous = _playing;
      _playing = this;
      if (previous != null && previous != this) {
        await previous._player?.pause();
      }
      if (!mounted || _playing != this) return;
      final player = _player ?? await _load();
      if (!mounted || player == null || _player != player || _playing != this) {
        return;
      }
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      if (!mounted || _player != player || _playing != this) return;
      unawaited(
        player.play().catchError((Object error) {
          if (mounted && _player == player) {
            setState(() {
              _failed = true;
              _isPlaying = false;
            });
          }
        }),
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _toggling = false;
    }
  }

  Future<AudioPlayer?> _load() async {
    final localPath = widget.localPath;
    final url = widget.url;
    if ((localPath == null || localPath.isEmpty) &&
        (url == null || url.isEmpty)) {
      setState(() => _failed = true);
      return null;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    final player = AudioPlayer();
    _player = player;
    _states = player.playerStateStream.listen((state) {
      if (!mounted || _player != player) return;
      final completed = state.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = state.playing && !completed;
        _loading =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        if (completed) _position = Duration.zero;
      });
      if (completed) unawaited(player.pause());
    });
    _positions = player.positionStream.listen((position) {
      if (mounted && _player == player) setState(() => _position = position);
    });
    try {
      Duration? duration;
      if (localPath != null && localPath.isNotEmpty) {
        try {
          duration = await player.setFilePath(localPath);
        } catch (_) {
          if (!mounted || _player != player) return null;
          if (url == null || url.isEmpty) rethrow;
          duration = await player.setUrl(url);
        }
      } else {
        duration = await player.setUrl(url!);
      }
      if (!mounted || _player != player) return null;
      _loadedDuration = duration;
      return player;
    } catch (_) {
      if (_player != player) return null;
      await _release();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.onAccent ? Colors.white : AppColors.textPrimary;
    final track = widget.onAccent
        ? Colors.white.withValues(alpha: .35)
        : AppColors.borderStrong;
    final total = _duration;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final shown = _isPlaying || _position > Duration.zero ? _position : total;

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => unawaited(_toggle()),
                    tooltip: _isPlaying ? 'Pause' : 'Play voice message',
                    icon: Icon(
                      _failed
                          ? Icons.error_outline_rounded
                          : _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: foreground,
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: foreground,
                inactiveTrackColor: track,
                thumbColor: foreground,
                disabledActiveTrackColor: foreground,
                disabledInactiveTrackColor: track,
                disabledThumbColor: foreground,
                overlayColor: foreground.withValues(alpha: .12),
              ),
              child: Slider(
                value: progress,
                onChanged: _player == null
                    ? null
                    : (value) => unawaited(
                        _player?.seek(
                          Duration(
                            milliseconds: (total.inMilliseconds * value)
                                .round(),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Text(
            _failed ? 'Unavailable' : formatVoiceDuration(shown),
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
