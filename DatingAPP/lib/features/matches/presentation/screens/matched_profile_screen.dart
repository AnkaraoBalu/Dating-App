import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/home_discover_data.dart';
import '../../../chat/data/chat_api.dart';
import '../../../chat/presentation/screens/conversation_screen.dart';
import '../../models/match_model.dart';
import '../../../home/presentation/widgets/home_person_photo.dart';

class MatchedProfileScreen extends StatelessWidget {
  const MatchedProfileScreen({
    super.key,
    required this.person,
    required this.chatApi,
    this.onMessage,
  });

  final HomePerson person;
  final ChatApi chatApi;

  /// Replaces the default "open a conversation" action, e.g. when this profile
  /// was opened from inside that conversation and should simply return to it.
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: AppColors.darkBackground,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    ),
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              actions: [
                IconButton(
                  tooltip: 'More options',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unmatch and report options are coming soon.',
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
              backgroundColor: AppColors.darkBackground,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              expandedHeight: 430,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _portrait(person),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xDD000000)],
                          stops: [.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${person.name}, ${person.age}',
                            style: AppTypography.h1.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            person.distance,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (person.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: person.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                labelStyle: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                backgroundColor: AppColors.surfaceSecondary,
                                side: const BorderSide(color: AppColors.border),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'About me',
                      style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      person.bio.isEmpty
                          ? 'A little mystery makes a great first conversation. Say hello and get to know ${person.name}.'
                          : person.bio,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: FilledButton.icon(
            onPressed:
                onMessage ??
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ConversationScreen(
                      match: MatchRecord(id: person.id, person: person),
                      api: chatApi,
                    ),
                  ),
                ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Send a message'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _portrait(HomePerson person) =>
    HomePersonPhoto.imageFor(person.image, personName: person.name);
