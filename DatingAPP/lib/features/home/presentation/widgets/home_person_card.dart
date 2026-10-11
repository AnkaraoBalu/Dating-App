import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/home_discover_data.dart';
import 'home_person_photo.dart';

/// Compact grid card for a discovery person.
class HomePersonCard extends StatelessWidget {
  const HomePersonCard({super.key, required this.person, this.onTap});

  final HomePerson person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 142,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withValues(alpha: .7)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            HomePersonPhoto.imageFor(person.image, personName: person.name),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE8000000)],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            if (person.online)
              const Positioned(
                left: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: AppColors.success,
                ),
              ),
            Positioned(
              left: 10,
              right: 8,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${person.name}, ${person.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    person.distance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
