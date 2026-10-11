import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/home_discover_data.dart';
import 'home_person_photo.dart';

part 'home_swipe_lead_card.dart';

abstract final class HomeDiscoverSections {
  static const _likeSwipeColor = Color(0xFF47D487);

  static Widget leadCard({
    Key? key,
    required HomePerson person,
    required VoidCallback onMore,
    required VoidCallback onPass,
    required VoidCallback onLike,
    required VoidCallback onTap,
    required bool liked,
  }) => _SwipeLeadCard(
    key: key,
    person: person,
    onMore: onMore,
    onPass: onPass,
    onLike: onLike,
    onTap: onTap,
    liked: liked,
  );

  static Widget _leadCardBody({
    required HomePerson person,
    required VoidCallback onMore,
    required VoidCallback onPass,
    required VoidCallback onLike,
    required VoidCallback onTap,
    required bool liked,
    required double dragX,
    required ValueChanged<double> onDragUpdate,
    required ValueChanged<double> onDragEnd,
    required VoidCallback onDragCancel,
  }) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
    onHorizontalDragEnd: (details) => onDragEnd(details.primaryVelocity ?? 0),
    onHorizontalDragCancel: onDragCancel,
    child: Container(
      height: 500,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: .65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          HomePersonPhoto.imageFor(person.image, personName: person.name),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
            ),
          ),
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: dragX.abs() > 24 ? 1 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: Transform.rotate(
                    angle: -.12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: dragX > 0
                              ? HomeDiscoverSections._likeSwipeColor
                              : AppColors.coral,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        dragX > 0 ? 'LIKE' : 'PASS',
                        style: TextStyle(
                          color: dragX > 0
                              ? HomeDiscoverSections._likeSwipeColor
                              : AppColors.coral,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.04, 0.38, 0.65, 1],
                colors: [
                  Color(0x33000000),
                  Colors.transparent,
                  Color(0x99000000),
                  Color(0xF5000000),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xAA432E29),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.peach,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${person.match}% match',
                    style: AppTypography.label.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _circleAction(Icons.more_horiz_rounded, onMore, light: true),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _circleAction(
                  Icons.close_rounded,
                  onPass,
                  accent: AppColors.coral,
                ),
                _circleAction(
                  Icons.replay_rounded,
                  () {},
                  accent: AppColors.warning,
                ),
                _circleAction(
                  Icons.favorite_rounded,
                  onLike,
                  filled: true,
                  accent: liked ? AppColors.coralPressed : AppColors.coral,
                ),
              ],
            ),
          ),
          Positioned(
            left: 17,
            right: 17,
            bottom: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${person.name}, ${person.age}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (person.verified)
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF4AA3FF),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (person.online)
                  Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF39D98A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online now',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF69E7A7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      _meta(Icons.location_on_rounded, person.distance),
                    ],
                  )
                else
                  _meta(Icons.location_on_rounded, person.distance),
                const SizedBox(height: 8),
                Text(
                  '“${person.bio}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: .94),
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: person.tags.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .18),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        person.tags[index],
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  static Widget _circleAction(
    IconData icon,
    VoidCallback onTap, {
    Color accent = Colors.white,
    bool filled = false,
    bool light = false,
  }) => Tooltip(
    message: filled
        ? 'Like profile'
        : icon == Icons.close_rounded
        ? 'Pass profile'
        : icon == Icons.replay_rounded
        ? 'Rewind'
        : 'Profile options',
    child: ClipOval(
      child: Material(
        color: filled
            ? const Color(0xFFFFF4E8)
            : Colors.black.withValues(alpha: light ? .42 : .38),
        shape: CircleBorder(
          side: BorderSide(
            color: filled ? AppColors.background : accent.withValues(alpha: .9),
            width: filled ? 0 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: filled ? 58 : 46,
            height: filled ? 58 : 46,
            child: Icon(
              icon,
              color: filled ? accent : Colors.white,
              size: filled ? 29 : 24,
            ),
          ),
        ),
      ),
    ),
  );

  static Widget _meta(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.white),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          value,
          style: AppTypography.caption.copyWith(color: Colors.white),
        ),
      ),
    ],
  );
}
