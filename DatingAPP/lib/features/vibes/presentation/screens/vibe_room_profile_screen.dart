import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';

class VibeRoomProfileScreen extends StatelessWidget {
  const VibeRoomProfileScreen({super.key, required this.member});

  final VibeRoomMember member;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: VibeRoomStore.instance,
    builder: (context, _) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 410,
              pinned: true,
              backgroundColor: AppColors.background,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      member.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: AppColors.peachSoft),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black26,
                            Colors.transparent,
                            Color(0xDD000000),
                          ],
                          stops: [0, .45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${member.name}, ${member.age}',
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontSize: 27,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${member.role} in this room · Online now',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(19, 20, 19, 32),
              sliver: SliverList.list(
                children: [
                  Text(
                    member.bio.isEmpty
                        ? 'Here to meet kind, interesting people and share a good conversation.'
                        : member.bio,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: member.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.surfaceSecondary,
                            side: BorderSide.none,
                            labelStyle: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 23),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '“My ideal connection starts with a great conversation and a little curiosity.”',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () =>
                        VibeRoomStore.instance.toggleFollow(member.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: Icon(
                      VibeRoomStore.instance.followingMemberIds.contains(
                            member.id,
                          )
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    label: Text(
                      VibeRoomStore.instance.followingMemberIds.contains(
                            member.id,
                          )
                          ? 'Following'
                          : 'Follow ${member.name}',
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
