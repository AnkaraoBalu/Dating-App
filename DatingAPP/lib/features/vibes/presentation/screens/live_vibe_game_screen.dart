import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_widgets.dart';
import 'game_results_screen.dart';

class LiveVibeGameScreen extends StatefulWidget {
  const LiveVibeGameScreen({
    super.key,
    required this.room,
    this.gameTitle = 'This or That',
    this.api,
  });

  final VibeRoom room;
  final String gameTitle;
  final VibeRoomsApi? api;

  @override
  State<LiveVibeGameScreen> createState() => _LiveVibeGameScreenState();
}

class _LiveVibeGameScreenState extends State<LiveVibeGameScreen> {
  static const _questions = <(String, String, String, String, String)>[
    (
      'What do you prefer for a weekend?',
      'Beach getaway',
      'City exploration',
      'assets/images/boys-images/rooftop_sunset_portrait.png',
      'assets/images/girls-images/city_night_portrait.png',
    ),
    (
      'Pick your perfect first date',
      'Coffee & a walk',
      'Dinner & a show',
      'assets/images/girls-images/cafe_coffee_portrait.png',
      'assets/images/girls-images/sunset_floral_portrait.png',
    ),
    (
      'Choose your evening mood',
      'Live music',
      'Movie night',
      'assets/images/boys-images/acoustic_guitar_portrait.png',
      'assets/images/girls-images/cozy_headphones_portrait.png',
    ),
    (
      'Your ideal mini adventure?',
      'A new food spot',
      'A scenic drive',
      'assets/images/girls-images/iced_coffee_portrait.png',
      'assets/images/boys-images/sunset_car_sunglasses.png',
    ),
    (
      'Choose a travel plan',
      'Mountains',
      'Ocean',
      'assets/images/boys-images/rooftop_sunset_portrait.png',
      'assets/images/girls-images/sunset_floral_portrait.png',
    ),
    (
      'What sounds more fun?',
      'Board games',
      'Arcade games',
      'assets/images/boys-images/cafe_smiling_portrait.png',
      'assets/images/boys-images/cafe_hoodie_portrait.png',
    ),
    (
      'Pick a perfect Sunday',
      'Slow brunch',
      'Spontaneous trip',
      'assets/images/girls-images/cafe_coffee_portrait.png',
      'assets/images/boys-images/rooftop_sunset_portrait.png',
    ),
    (
      'One playlist for the road?',
      'Indie favorites',
      'Old-school hits',
      'assets/images/boys-images/acoustic_guitar_portrait.png',
      'assets/images/girls-images/cozy_headphones_portrait.png',
    ),
  ];
  static const _preferredAnswers = [0, 0, 1, 0, 0, 1, 0, 1];

  int _questionIndex = 0;
  int _score = 0;
  int? _selectedAnswer;

  void _answer(int choice) {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = choice;
      if (choice == _preferredAnswers[_questionIndex]) _score++;
    });
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (_questionIndex + 1 == _questions.length) {
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => GameResultsScreen(
              room: widget.room,
              gameTitle: widget.gameTitle,
              api: widget.api,
              score: _score,
              total: _questions.length,
            ),
          ),
        );
      } else {
        setState(() {
          _questionIndex++;
          _selectedAnswer = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_questionIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.gameTitle,
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_questionIndex + 1} of ${_questions.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (_questionIndex + 1) / _questions.length,
                minHeight: 8,
                backgroundColor: AppColors.surfaceSecondary,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 21),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeRoomAvatar(
                  image: VibeRoomSeeds.aanya.avatar,
                  size: 48,
                  borderColor: AppColors.surface,
                ),
                const SizedBox(width: 42),
                VibeRoomAvatar(
                  image: VibeRoomSeeds.rohan.avatar,
                  size: 48,
                  borderColor: AppColors.surface,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.peachSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                question.$1,
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _ChoiceCard(
                    label: question.$2,
                    image: question.$4,
                    selected: _selectedAnswer == 0,
                    onTap: () => _answer(0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceCard(
                    label: question.$3,
                    image: question.$5,
                    selected: _selectedAnswer == 1,
                    onTap: () => _answer(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'See what others chose',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final member in widget.room.members.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: VibeRoomAvatar(
                      image: member.avatar,
                      size: 34,
                      borderColor: AppColors.surface,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Leave game'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.coral : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              child: Image.asset(
                image,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
