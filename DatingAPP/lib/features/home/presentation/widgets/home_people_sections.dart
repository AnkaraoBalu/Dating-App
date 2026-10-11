part of '../screens/home_screen.dart';

extension _HomePeopleSections on _HomeScreenState {
  Widget _sectionHeading(String title, VoidCallback onSeeAll) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      TextButton(
        onPressed: onSeeAll,
        child: Text(
          'See all',
          style: AppTypography.label.copyWith(color: AppColors.coral),
        ),
      ),
    ],
  );

  Widget _nearbyPeople() {
    final people = _nearby;
    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Text(
          'More people are joining nearby. Check back soon.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => HomePersonCard(
          person: people[index],
          onTap: () => _openPreview(people[index]),
        ),
      ),
    );
  }

  Widget _peopleState() {
    if (_loadingPeople) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final message = _peopleError != null
        ? 'Could not load profiles. Check your connection and try again.'
        : 'No profiles match these filters yet. Try a wider age range or distance.';
    return Column(
      children: [
        Icon(
          _peopleError == null
              ? Icons.people_outline_rounded
              : Icons.cloud_off_rounded,
          size: 42,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (_peopleError != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: _loadPeople, child: const Text('Retry')),
        ],
      ],
    );
  }
}
