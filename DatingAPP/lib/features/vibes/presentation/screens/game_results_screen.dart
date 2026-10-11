import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_widgets.dart';
import 'live_vibe_room_screen.dart';

class GameResultsScreen extends StatelessWidget {
  const GameResultsScreen({
    super.key,
    required this.room,
    required this.gameTitle,
    required this.score,
    required this.total,
    this.api,
  });

  final VibeRoom room;
  final String gameTitle;
  final int score;
  final int total;
  final VibeRoomsApi? api;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Game results',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        IconButton(
          tooltip: 'Share results',
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(
                text:
                    '$gameTitle: I matched on $score out of $total in ${room.title}!',
              ),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game results copied.')),
            );
          },
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 25, 22, 25),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VibeRoomAvatar(
                image: VibeRoomSeeds.aanya.avatar,
                size: 94,
                borderColor: AppColors.coral,
              ),
              const SizedBox(width: 16),
              VibeRoomAvatar(
                image: VibeRoomSeeds.rohan.avatar,
                size: 94,
                borderColor: AppColors.verified,
              ),
            ],
          ),
          const SizedBox(height: 21),
          const Icon(
            Icons.celebration_rounded,
            size: 40,
            color: AppColors.coral,
          ),
          const SizedBox(height: 9),
          Text(
            'You matched on\n$score out of $total!',
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$gameTitle · ${room.title}',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Text(
            'Great vibes! You both have similar choices and interests.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 23),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _MatchPill(icon: '✈️', label: 'Love Travelling'),
              _MatchPill(icon: '☕', label: 'Coffee & Cafés'),
              _MatchPill(icon: '🌙', label: 'Night Owl'),
              _MatchPill(icon: '🎵', label: 'Music'),
              _MatchPill(icon: '✨', label: 'Spontaneous Plans'),
              _MatchPill(icon: '🐶', label: 'Dogs'),
            ],
          ),
          const SizedBox(height: 25),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => LiveVibeRoomScreen(room: room, api: api),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(51),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Start chatting'),
          ),
          const SizedBox(height: 9),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size.fromHeight(49),
            ),
            child: const Text('Back to room'),
          ),
        ],
      ),
    ),
  );
}

class _MatchPill extends StatelessWidget {
  const _MatchPill({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      '$icon  $label',
      style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
    ),
  );
}
