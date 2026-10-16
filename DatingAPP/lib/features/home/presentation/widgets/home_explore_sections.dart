part of '../screens/home_screen.dart';

extension _HomeExploreSections on _HomeScreenState {
  // Grow with the system text size so the two text lines always fit.
  Widget _exploreModes() => SizedBox(
    height: 49 + MediaQuery.textScalerOf(context).scale(56),
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _modeTile(
          Icons.grid_view_rounded,
          'Interests',
          'Find your vibe',
          _openCategories,
        ),
        _modeTile(
          Icons.circle,
          'Online now',
          'Ready to chat',
          () => _openPeople(DiscoverPeopleMode.online),
          color: AppColors.success,
        ),
        _modeTile(
          Icons.auto_awesome_rounded,
          'New faces',
          'Fresh profiles',
          () => _openPeople(DiscoverPeopleMode.newFaces),
        ),
        _modeTile(Icons.map_outlined, 'Map view', 'Around you', _openMap),
        _modeTile(
          Icons.flight_takeoff_rounded,
          'Travel mode',
          'Explore cities',
          _openTravel,
        ),
      ],
    ),
  );

  Widget _modeTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color color = AppColors.coral,
  }) => Padding(
    padding: const EdgeInsets.only(right: 9),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Ink(
        width: 148,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // Hidden for now; see home_feed_layout.dart.
  // ignore: unused_element
  Widget _upgradeBanner() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFE3D1), Color(0xFFFFD5D5)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.coralSoft),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.coralPressed,
            size: 28,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get 3× more matches',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Unlock more ways to connect',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _notice('Just2+ is coming soon.'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: const Text('Upgrade'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
