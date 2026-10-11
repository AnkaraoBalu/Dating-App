part of '../screens/onboarding_questions_screen.dart';

extension _OnboardingFlowActions on _OnboardingQuestionsScreenState {
  int _resumeStep(OnboardingProfile? profile) {
    if (profile?.birthDate == null) return 0;
    if (profile?.genderIdentity == null) return 1;
    if (profile?.interestedIn == null) return 2;
    final skipped = profile?.skippedQuestions ?? const <String>[];
    if (profile?.vibeType == null && !skipped.contains('vibe_type')) return 4;
    if (profile?.idealFriday == null && !skipped.contains('ideal_friday')) {
      return 5;
    }
    if ((profile?.interests.isEmpty ?? true) &&
        !skipped.contains('interests')) {
      return 6;
    }
    if ((profile?.musicGenres.isEmpty ?? true) &&
        (profile?.favoriteArtists.isEmpty ?? true) &&
        !skipped.contains('music')) {
      return 7;
    }
    if (profile?.currentEra == null && !skipped.contains('current_era')) {
      return 8;
    }
    if ((profile?.dealbreakers.isEmpty ?? true) &&
        !skipped.contains('dealbreakers')) {
      return 9;
    }
    if ((profile?.datingIntentions.isEmpty ?? true) &&
        !skipped.contains('dating_intentions')) {
      return 10;
    }
    return skipped.contains('location_preferences') ? 12 : 11;
  }

  bool get _isAdult {
    final today = DateTime.now();
    var age = today.year - _birthDate.year;
    if (today.month < _birthDate.month ||
        (today.month == _birthDate.month && today.day < _birthDate.day)) {
      age--;
    }
    return age >= 18;
  }

  bool get _canContinue => switch (_step) {
    0 => _isAdult && _name.trim().isNotEmpty && _name.trim().length <= 80,
    1 => _gender != null,
    2 => _interestedIn != null,
    3 => true,
    4 => _vibeType != null,
    5 => _idealFriday != null,
    6 => _selectedInterests.isNotEmpty && _selectedInterests.length <= 5,
    7 =>
      (_selectedGenres.isNotEmpty || _selectedArtists.isNotEmpty) &&
          _selectedGenres.length + _selectedArtists.length <= 5,
    8 => _currentEra != null,
    9 =>
      _dealbreakers.length <= 8 &&
          !(_dealbreakers.contains('no_hard_dealbreakers') &&
              _dealbreakers.length > 1),
    10 => _intentions.isNotEmpty,
    11 => true,
    _ => true,
  };

  Future<void> _continue() async {
    if (_busy || !_canContinue) return;
    _refresh(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_step == 0) await widget.api.updateName(_name);
      final changes = switch (_step) {
        0 => <String, Object?>{
          'birthDate': _birthDate.toIso8601String().split('T').first,
        },
        1 => <String, Object?>{'genderIdentity': _gender},
        2 => <String, Object?>{'interestedIn': _interestedIn},
        3 => <String, Object?>{},
        4 => <String, Object?>{'vibeType': _vibeType},
        5 => <String, Object?>{'idealFriday': _idealFriday},
        6 => <String, Object?>{'interests': _selectedInterests.toList()},
        7 => <String, Object?>{
          'musicGenres': _selectedGenres.toList(),
          'favoriteArtists': _selectedArtists.toList(),
        },
        8 => <String, Object?>{'currentEra': _currentEra},
        9 => <String, Object?>{'dealbreakers': _dealbreakers.toList()},
        10 => <String, Object?>{'datingIntentions': _intentions.toList()},
        11 => <String, Object?>{
          'preferredDistanceKm': _preferredDistanceKm,
          'onlyShowPeopleNearby': _onlyShowPeopleNearby,
        },
        _ => <String, Object?>{},
      };
      final skippedKey = _skipKey(_step);
      if (skippedKey != null) {
        changes['skippedQuestions'] =
            (_skippedQuestions.toSet()..remove(skippedKey)).toList();
      }
      if (changes.isNotEmpty) await widget.api.update(changes);
      if (skippedKey != null) _skippedQuestions.remove(skippedKey);
      if (!mounted) return;
      if (_step == 12) {
        await widget.api.complete();
        if (!mounted) return;
        await Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => OnboardingCompleteScreen(
              genderIdentity: _gender,
              profileApi: ProfileSetupApi(
                baseUrl: widget.api.baseUrl,
                getSessionToken: widget.api.getSessionToken,
              ),
            ),
          ),
        );
      } else if (_editingSummary) {
        _refresh(() {
          _step = 12;
          _editingSummary = false;
        });
      } else {
        _refresh(() => _step++);
      }
    } catch (error) {
      if (mounted) _refresh(() => _error = error.toString());
    } finally {
      if (mounted) _refresh(() => _busy = false);
    }
  }

  String? _skipKey(int step) => switch (step) {
    4 => 'vibe_type',
    5 => 'ideal_friday',
    6 => 'interests',
    7 => 'music',
    8 => 'current_era',
    9 => 'dealbreakers',
    10 => 'dating_intentions',
    11 => 'location_preferences',
    _ => null,
  };

  Future<void> _skip() async {
    final key = _skipKey(_step);
    if (_busy || key == null) return;
    _refresh(() {
      _busy = true;
      _error = null;
    });
    try {
      final skipped = {..._skippedQuestions, key};
      final changes = <String, Object?>{'skippedQuestions': skipped.toList()};
      switch (_step) {
        case 4:
          changes['vibeType'] = null;
          break;
        case 5:
          changes['idealFriday'] = null;
          break;
        case 6:
          changes['interests'] = <String>[];
          break;
        case 7:
          changes['musicGenres'] = <String>[];
          changes['favoriteArtists'] = <String>[];
          break;
        case 8:
          changes['currentEra'] = null;
          break;
        case 9:
          changes['dealbreakers'] = <String>[];
          break;
        case 10:
          changes['datingIntentions'] = <String>[];
          break;
      }
      await widget.api.update(changes);
      if (!mounted) return;
      _refresh(() {
        _skippedQuestions = skipped;
        switch (_step) {
          case 4:
            _vibeType = null;
            break;
          case 5:
            _idealFriday = null;
            break;
          case 6:
            _selectedInterests.clear();
            break;
          case 7:
            _selectedGenres.clear();
            _selectedArtists.clear();
            break;
          case 8:
            _currentEra = null;
            break;
          case 9:
            _dealbreakers.clear();
            break;
          case 10:
            _intentions.clear();
            break;
        }
        if (_editingSummary) {
          _step = 12;
          _editingSummary = false;
        } else {
          _step++;
        }
      });
    } catch (error) {
      if (mounted) _refresh(() => _error = error.toString());
    } finally {
      if (mounted) _refresh(() => _busy = false);
    }
  }

  void _back() {
    if (_busy) return;
    if (_editingSummary) {
      _refresh(() {
        _step = 12;
        _editingSummary = false;
        _error = null;
      });
      return;
    }
    if (_step > 0) {
      _refresh(() {
        _step--;
        _error = null;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }
}
