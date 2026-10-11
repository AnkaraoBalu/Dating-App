import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/presentation/screens/profile_quick_preview_screen.dart';
import '../../../home/data/discover_api.dart';
import '../../../chat/data/chat_api.dart';
import '../../data/match_controller.dart';
import '../../models/match_model.dart';
import '../navigation/match_navigation.dart';
import '../../../home/presentation/widgets/home_person_photo.dart';

class LikesReceivedScreen extends StatelessWidget {
  const LikesReceivedScreen({
    super.key,
    required this.controller,
    this.currentUserImage,
  });

  final MatchController controller;
  final String? currentUserImage;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Likes received',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: controller.incomingLikesLoading && controller.incomingLikes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            )
          : controller.incomingLikes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.coral,
                      size: 66,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.incomingLikesError == null
                          ? 'No new likes yet'
                          : 'Could not load likes',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      controller.incomingLikesError ??
                          'When someone likes your profile, you’ll see them here.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (controller.incomingLikesError != null) ...[
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: controller.loadIncomingLikes,
                        child: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.incomingLikes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _IncomingLikeCard(
                key: ValueKey(controller.incomingLikes[index].person.id),
                controller: controller,
                incoming: controller.incomingLikes[index],
                currentUserImage: currentUserImage,
              ),
            ),
    ),
  );
}

class _IncomingLikeCard extends StatefulWidget {
  const _IncomingLikeCard({
    super.key,
    required this.controller,
    required this.incoming,
    this.currentUserImage,
  });

  final MatchController controller;
  final MatchRecord incoming;
  final String? currentUserImage;

  @override
  State<_IncomingLikeCard> createState() => _IncomingLikeCardState();
}

class _IncomingLikeCardState extends State<_IncomingLikeCard> {
  bool _liking = false;
  DiscoverApi get _discoverApi => widget.controller.discoverApi;

  @override
  Widget build(BuildContext context) {
    final person = widget.incoming.person;
    final image = person.image;
    return Container(
      height: 286,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          HomePersonPhoto.imageFor(image, personName: person.name),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xE8000000)],
                stops: [.35, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${person.name}, ${person.age}',
                        style: AppTypography.h2.copyWith(color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.favorite_rounded, color: AppColors.coral),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${person.name} liked your profile',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (person.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    person.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _liking
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProfileQuickPreviewScreen(
                                      person: person,
                                      api: _discoverApi,
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  unawaited(widget.controller.load());
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: const Text('View profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _liking || _discoverApi.hasLiked(person.id)
                            ? null
                            : _likeBack,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                        ),
                        icon: _liking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.favorite_rounded, size: 17),
                        label: const Text('Like back'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _likeBack() async {
    if (_liking) return;
    final incoming = widget.incoming;
    final controller = widget.controller;
    final ownImage = widget.currentUserImage;
    final chatApi = _chatApi();
    setState(() => _liking = true);
    try {
      final didMatch = await controller.likeIncoming(incoming);
      if (!mounted) return;
      if (didMatch) {
        await MatchNavigation.celebrate(
          context,
          person: incoming.person,
          chatApi: chatApi,
          currentUserImage: ownImage,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You liked ${incoming.person.name}.')),
        );
      }
      if (mounted) await controller.load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not like this profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  ChatApi _chatApi() => ChatApi(
    baseUrl: widget.controller.api.baseUrl,
    getSessionToken: widget.controller.api.getSessionToken,
  );
}
