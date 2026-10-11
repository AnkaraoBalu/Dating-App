part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupDetailsSections on _ProfileSetupScreenState {
  Widget _bioBody() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: TextField(
          controller: _bio,
          maxLength: 200,
          minLines: 7,
          maxLines: 9,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText:
                'Engineer by day, playlists by night. I love good food and conversations…',
          ),
        ),
      ),
      const SizedBox(height: 18),
      _tipBox('Bio tips', [
        'Be authentic',
        'Mention your interests',
        'Keep it short and interesting',
      ]),
    ],
  );

  Widget _basicsIntro() => Column(
    children: [
      const SizedBox(height: 24),
      Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(36),
        ),
        child: const Icon(
          Icons.badge_outlined,
          color: AppColors.coral,
          size: 96,
        ),
      ),
      const SizedBox(height: 24),
      _tipBox('Your basics help you', [
        'Find people nearby',
        'Show what matters to you',
        'You can change these details anytime',
      ]),
    ],
  );

  Widget _music() => Column(
    children: [
      const SizedBox(height: 60),
      const CircleAvatar(
        radius: 42,
        backgroundColor: AppColors.spotify,
        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 45),
      ),
      const SizedBox(height: 28),
      Text('Connect Spotify', style: AppTypography.h2),
      const SizedBox(height: 16),
      Text(
        'Link your Spotify to show your top artists, playlists and music taste.',
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spotify connection is coming soon.')),
        ),
        style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
        child: const Text('Connect Spotify'),
      ),
    ],
  );

  Widget _verify() => Column(
    children: [
      const SizedBox(height: 45),
      Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 58,
            backgroundImage: AssetImage(_photoPlaceholders[0]),
          ),
          const Positioned(
            right: -5,
            top: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.success,
              child: Icon(Icons.check_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      const SizedBox(height: 42),
      _tipBox('Selfie verification', [
        'Proves you’re real',
        'Helps keep the community safe',
        'Builds genuine connections',
      ]),
      const SizedBox(height: 16),
      Text(
        'Verification will be available when profile services are connected.',
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}
