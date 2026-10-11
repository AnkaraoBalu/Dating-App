part of '../screens/match_celebration_screen.dart';

// Portraits and action rows shown on the match celebration.
extension _MatchCelebrationSections on _MatchCelebrationScreenState {
  Widget _animatedPortrait(double size, String? image, String? name, bool own) {
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutBack,
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(own ? -.35 : .35, .08),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: .82, end: 1).animate(animation),
          child: Semantics(
            label: own ? 'Your profile photo' : '$name’s profile photo',
            image: true,
            child: _personCircle(size, image, name),
          ),
        ),
      ),
    );
  }

  Widget _personCircle(double size, String? image, String? name) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFFF7187), width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.coral.withValues(alpha: .35),
          blurRadius: 20,
        ),
      ],
    ),
    child: ClipOval(
      child: image == null || image.isEmpty
          ? const ColoredBox(
              color: Color(0xFF24322F),
              child: Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white54,
                  size: 46,
                ),
              ),
            )
          : HomePersonPhoto.imageFor(image, personName: name),
    ),
  );

  Widget _matchActionRow(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: .22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF7187), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white38,
            size: 19,
          ),
        ],
      ),
    ),
  );
}
