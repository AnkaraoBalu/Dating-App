import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../models/vibe_room.dart';
import 'live_vibe_game_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';

class IcebreakerGamesScreen extends StatelessWidget {
  const IcebreakerGamesScreen({super.key, required this.room, this.api});

  final VibeRoom room;
  final VibeRoomsApi? api;

  static const _games = <(String, String, String, String)>[
    ('This or That', '💞', '2–8 players', '3 min'),
    ('Red Flag / Green Flag', '🚩', '2–8 players', '3 min'),
    ('Would You Rather?', '❔', '2–8 players', '3 min'),
    ('Guess My Vibe', '💝', '2–8 players', '5 min'),
    ('Two Truths and a Lie', '🫶', '2–8 players', '3 min'),
    ('Chemistry Check', '💞', '2–8 players', '5 min'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Break the ice ✨',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        IconButton(
          tooltip: 'Room options',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game settings are available to the room host.'),
            ),
          ),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 3, 17, 25),
        children: [
          Text(
            'A little fun makes every connection easier.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _games.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 360 ? 1 : 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) => _GameTile(
              title: _games[index].$1,
              emoji: _games[index].$2,
              players: _games[index].$3,
              duration: _games[index].$4,
              onPlay: () => _play(context, _games[index].$1),
            ),
          ),
          const SizedBox(height: 23),
          VibeRoomSectionTitle(title: 'Trending in this room'),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('💞', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This or That',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '12 people playing',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => _play(context, 'This or That'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _play(BuildContext context, String title) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              LiveVibeGameScreen(room: room, gameTitle: title, api: api),
        ),
      );
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.title,
    required this.emoji,
    required this.players,
    required this.duration,
    required this.onPlay,
  });
  final String title;
  final String emoji;
  final String players;
  final String duration;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 45)),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$players · $duration',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton(
              onPressed: onPlay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: const Text('Play'),
            ),
          ),
        ],
      ),
    ),
  );
}
