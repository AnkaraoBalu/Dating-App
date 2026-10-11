import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/adaptive_flow_column.dart';
import '../../data/onboarding_api.dart';
import '../../data/onboarding_question_copy.dart';
import '../../data/onboarding_question_options.dart';
import '../../models/onboarding_profile.dart';
import '../../../profile_setup/data/profile_setup_api.dart';
import '../widgets/onboarding_choice_tile.dart';
import '../widgets/onboarding_location_question.dart';
import '../widgets/onboarding_music_question.dart';
import 'onboarding_complete_screen.dart';

part '../widgets/onboarding_background.dart';

part '../controllers/onboarding_flow_actions.dart';
part '../widgets/onboarding_basics_layout.dart';
part '../widgets/onboarding_vibe_layout.dart';
part '../widgets/onboarding_intro_section.dart';
part '../widgets/onboarding_answer_sections.dart';
part '../widgets/onboarding_summary_section.dart';

class OnboardingQuestionsScreen extends StatefulWidget {
  const OnboardingQuestionsScreen({
    super.key,
    required this.api,
    required this.initialProfile,
  });

  final OnboardingApi api;
  final OnboardingProfile? initialProfile;

  @override
  State<OnboardingQuestionsScreen> createState() =>
      _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState extends State<OnboardingQuestionsScreen> {
  static const _basicsSteps = OnboardingQuestionCopy.basicsStepCount;
  static const _vibeSteps = OnboardingQuestionCopy.vibeStepCount;
  late String _name;
  late DateTime _birthDate;
  late String? _gender;
  late String? _interestedIn;
  late String? _vibeType;
  late String? _idealFriday;
  late String? _currentEra;
  late Set<String> _intentions;
  late Set<String> _selectedInterests;
  late Set<String> _selectedGenres;
  late Set<String> _selectedArtists;
  late Set<String> _dealbreakers;
  late Set<String> _skippedQuestions;
  late int _preferredDistanceKm;
  late bool _onlyShowPeopleNearby;
  late int _step;
  bool _busy = false;
  String? _error;
  bool _editingSummary = false;

  DateTime get _maximumBirthDate {
    final today = DateTime.now();
    return DateTime(today.year - 18, today.month, today.day);
  }

  void _refresh(VoidCallback mutation) => setState(mutation);

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _name = profile?.username ?? '';
    final today = DateTime.now();
    _birthDate =
        profile?.birthDate?.toLocal() ??
        DateTime(today.year - 25, today.month, today.day);
    _gender = profile?.genderIdentity;
    _interestedIn = profile?.interestedIn;
    _vibeType = profile?.vibeType;
    _idealFriday = profile?.idealFriday;
    _currentEra = profile?.currentEra;
    _intentions = {...?profile?.datingIntentions};
    _selectedInterests = {...?profile?.interests};
    _selectedGenres = {...?profile?.musicGenres};
    _selectedArtists = {...?profile?.favoriteArtists};
    _dealbreakers = {...?profile?.dealbreakers};
    _skippedQuestions = {...?profile?.skippedQuestions};
    _preferredDistanceKm = profile?.preferredDistanceKm ?? 25;
    _onlyShowPeopleNearby = profile?.onlyShowPeopleNearby ?? true;
    _step = _resumeStep(profile);
  }

  @override
  Widget build(BuildContext context) => _step < _basicsSteps || _step == 10
      ? _buildBasicsScreen()
      : _buildVibeScreen();

  void _toggleDealbreaker(String value) {
    if (value == 'no_hard_dealbreakers') {
      if (_dealbreakers.contains(value)) {
        _dealbreakers.remove(value);
      } else {
        _dealbreakers
          ..clear()
          ..add(value);
      }
      return;
    }
    _dealbreakers.remove('no_hard_dealbreakers');
    if (_dealbreakers.contains(value)) {
      _dealbreakers.remove(value);
    } else if (_dealbreakers.length < 8) {
      _dealbreakers.add(value);
    }
  }

  void _toggleInterest(String value) {
    if (_selectedInterests.contains(value)) {
      _selectedInterests.remove(value);
    } else if (_selectedInterests.length < 5) {
      _selectedInterests.add(value);
    }
  }
}
