import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_widgets.dart';

class LiveVibeVoiceScreen extends StatefulWidget {
  const LiveVibeVoiceScreen({
    super.key,
    required this.room,
    required this.onLeave,
    required this.onOpenPeople,
    required this.onOpenGames,
    this.leaving = false,
  });

  final VibeRoom room;
  final VoidCallback onLeave;
  final VoidCallback onOpenPeople;
  final VoidCallback onOpenGames;
  final bool leaving;

  @override
  State<LiveVibeVoiceScreen> createState() => _LiveVibeVoiceScreenState();
}

class _LiveVibeVoiceScreenState extends State<LiveVibeVoiceScreen> {
  bool _micOn = true;
  bool _speakerOn = true;
  bool _handRaised = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Row(
        children: [
          const Icon(Icons.headphones_rounded, color: AppColors.coral),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${widget.room.participantCount} people live',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.leaving ? null : widget.onLeave,
          child: const Text('Leave'),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              widget.room.title,
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Text(
            'Voice room · ${widget.room.participantCount} people live',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(child: _stage()),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _handRaised = !_handRaised),
              icon: Icon(
                _handRaised ? Icons.check_rounded : Icons.back_hand_outlined,
              ),
              label: Text(_handRaised ? 'Request sent' : 'Request to speak'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coralPressed,
                side: const BorderSide(color: AppColors.coral),
              ),
            ),
          ),
          _controls(),
        ],
      ),
    ),
  );

  Widget _stage() {
    final members = widget.room.members.take(5).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final points = <Offset>[
          Offset(width * .15, height * .23),
          Offset(width * .72, height * .21),
          Offset(width * .16, height * .57),
          Offset(width * .72, height * .57),
          Offset(width * .44, height * .72),
        ];
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coralSoft.withValues(alpha: .6),
              ),
              child: Center(
                child: VibeRoomAvatar(
                  image: widget.room.hostAvatar,
                  size: 102,
                  borderColor: AppColors.coral,
                ),
              ),
            ),
            Positioned(
              bottom: height * .28,
              child: Text(
                '${widget.room.hostName}\nSpeaking…',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.coralPressed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (var index = 0; index < members.length; index++)
              Positioned(
                left: points[index].dx,
                top: points[index].dy,
                child: GestureDetector(
                  onTap: widget.onOpenPeople,
                  child: Column(
                    children: [
                      VibeRoomAvatar(
                        image: members[index].avatar,
                        size: 54,
                        borderColor: members[index].role == 'Host'
                            ? AppColors.coral
                            : AppColors.borderStrong,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        members[index].name,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _controls() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VoiceControlButton(
              icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: _micOn ? 'Mic on' : 'Muted',
              active: _micOn,
              onTap: () => setState(() => _micOn = !_micOn),
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: _speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: 'Speaker',
              active: _speakerOn,
              onTap: () => setState(() => _speakerOn = !_speakerOn),
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: Icons.back_hand_rounded,
              label: 'Raise hand',
              active: _handRaised,
              onTap: () => setState(() => _handRaised = !_handRaised),
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: Icons.people_alt_outlined,
              label: 'People',
              active: false,
              onTap: widget.onOpenPeople,
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: Icons.more_horiz_rounded,
              label: 'Games',
              active: false,
              onTap: widget.onOpenGames,
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: Icons.call_end_rounded,
              label: 'Leave',
              active: false,
              destructive: true,
              onTap: widget.leaving ? () {} : widget.onLeave,
            ),
          ),
        ],
      ),
    ),
  );
}

class _VoiceControlButton extends StatelessWidget {
  const _VoiceControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: destructive
                ? AppColors.coral
                : (active ? AppColors.coralSoft : AppColors.surfaceSecondary),
            child: Icon(
              icon,
              size: 20,
              color: destructive ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    ),
  );
}
