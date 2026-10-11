part of '../screens/profile_setup_screen.dart';

extension _ProfileSetupPreviewHero on _ProfileSetupScreenState {
  Widget _previewHero(int photoCount) => Container(
    height: 410,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F271C12),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        photoCount > 0
            ? _photo(0)
            : ColoredBox(
                color: AppColors.surfaceSecondary,
                child: Icon(
                  Icons.person_outline,
                  size: 92,
                  color: AppColors.textTertiary,
                ),
              ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.2, 0.55, 1],
              colors: [Color(0x15000000), Color(0x16000000), Color(0xE8000000)],
            ),
          ),
        ),
        Positioned(
          top: 15,
          left: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, color: Colors.white, size: 15),
                SizedBox(width: 6),
                Text(
                  'PROFILE PREVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.hero.copyWith(color: Colors.white),
                    ),
                  ),
                  if (_verificationStatus == 'verified') ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF83C5FF),
                      size: 22,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 9),
              if ((_basicValues['location'] ?? '').isNotEmpty)
                _heroMeta(Icons.location_on_rounded, _basicValues['location']!),
              if ((_basicValues['education'] ?? '').isNotEmpty ||
                  (_basicValues['fieldOfStudy'] ?? '').isNotEmpty)
                _heroMeta(
                  Icons.school_rounded,
                  [_basicValues['education'], _basicValues['fieldOfStudy']]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                ),
              if ((_basicValues['jobTitle'] ?? '').isNotEmpty)
                _heroMeta(
                  Icons.work_rounded,
                  [_basicValues['jobTitle'], _basicValues['company']]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' · '),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _heroMeta(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: .9)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: .95),
            ),
          ),
        ),
      ],
    ),
  );
}
