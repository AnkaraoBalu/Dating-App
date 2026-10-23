part of '../screens/home_screen.dart';

extension _HomeDiscoveryActions on _HomeScreenState {
  List<String> get _activeInterests => <String?>[
    ..._filters.interests,
    _selectedInterest,
  ].whereType<String>().toList();

  Future<void> _replayPassedProfiles() async {
    if (_nextReplayBefore == null ||
        _pendingPassIds.isNotEmpty ||
        _pendingLikeIds.isNotEmpty) {
      return;
    }
    // Persist the same cutoff across refreshes, filter changes and restarts.
    // Server pass timestamps exclude anyone swiped again after this cutoff.
    final cutoff = _nextReplayBefore!;
    final memberId =
        _roundMemberId ??
        _profileController?.profile?.data['userId'] as String?;
    final api = widget.discoverApi;
    if (memberId == null || api == null) {
      _notice('Could not load your round preferences. Please try again.');
      return;
    }
    try {
      await _roundStore.save(api.baseUrl, memberId, cutoff);
    } catch (error) {
      debugPrint('[DiscoveryRound] Could not save round: $error');
      if (mounted) _notice('Could not save your round. Please try again.');
      return;
    }
    if (!mounted) return;
    _replayBefore = cutoff;
    _dismissedUserIds.removeAll(_passedUserIds);
    _passedUserIds.clear();
    await _loadPeople(nearbyAlso: false);
  }

  void _prefetchDiscoveryPhotos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _people.isEmpty) return;
      final index = _feedController.hasClients
          ? (_feedController.page ?? 0).round()
          : 0;
      for (final person in _people.skip(index).take(3)) {
        final provider = HomePersonPhoto.providerFor(
          person.image,
          personName: person.name,
        );
        if (provider != null) {
          unawaited(
            precacheImage(
              provider,
              context,
              onError: (error, stack) {
                debugPrint('[DiscoverPhoto] Prefetch failed: $error');
              },
            ),
          );
        }
      }
    });
  }

  Future<void> _recordActivity() async {
    try {
      await widget.discoverApi?.recordActivity();
    } catch (_) {}
  }

  Future<void> _refillPeopleIfNeeded() async {
    if (!mounted ||
        !_preferencesReady ||
        _loadingPeople ||
        _people.length > 5) {
      return;
    }
    if (_refillingPeople) {
      _refillQueued = true;
      return;
    }
    await _loadPeople(nearbyAlso: false, append: true);
  }

  Future<void> _loadPeople({
    bool nearbyAlso = true,
    bool append = false,
  }) async {
    final requestId = ++_peopleRequest;
    _refillingPeople = append;
    _refillQueued = false;
    final api = widget.discoverApi;
    if (api == null) {
      if (mounted) {
        _refresh(() {
          _loadingPeople = false;
          _peopleError = 'Discover service is unavailable.';
        });
      }
      return;
    }
    _refresh(() {
      _loadingPeople = !append || _people.isEmpty;
      _peopleError = null;
    });
    try {
      final location = _travelLocation;
      final args = <String, Object?>{
        'mode': switch (_selectedTab) {
          1 => 'nearby',
          2 => 'trending',
          _ => 'for_you',
        },
        'minAge': _filters.minAge,
        'maxAge': _filters.maxAge,
        'gender': _filters.gender,
        'location': location,
        'interest': _selectedInterest ?? _filters.interest,
        'interests': _activeInterests,
        'radiusKm': _profileController?.profile == null
            ? null
            : _filters.radiusKm,
        'onlineOnly': _filters.onlineOnly,
        'verifiedOnly': _filters.verifiedOnly,
      };
      String? emptyReason;
      String? nextReplayBefore;
      final peopleRequest = api.discover(
        replayBefore: _replayBefore,
        onReplayBefore: (token) => nextReplayBefore = token,
        onEmptyReason: (reason) => emptyReason = reason,
        mode: args['mode']! as String,
        minAge: args['minAge']! as int,
        maxAge: args['maxAge']! as int,
        gender: args['gender'] as String,
        location: args['location'] as String?,
        interest: args['interest'] as String?,
        interests: args['interests']! as List<String>,
        radiusKm: args['radiusKm'] as int?,
        onlineOnly: args['onlineOnly']! as bool,
        verifiedOnly: args['verifiedOnly']! as bool,
      );
      // Fetch the nearby strip at the same time instead of after the feed.
      final nearbyRequest = nearbyAlso && _selectedTab == 0
          ? api.discover(
              mode: 'nearby',
              minAge: _filters.minAge,
              maxAge: _filters.maxAge,
              gender: _filters.gender,
              location: location,
              interest: _selectedInterest ?? _filters.interest,
              interests: _activeInterests,
              radiusKm: args['radiusKm'] as int?,
              onlineOnly: _filters.onlineOnly,
              verifiedOnly: _filters.verifiedOnly,
            )
          : null;
      final results = await Future.wait([peopleRequest, ?nearbyRequest]);
      final people = results.first;
      final nearby = nearbyRequest == null ? null : results.last;
      if (!mounted || requestId != _peopleRequest) return;
      _refresh(() {
        _people = mergeDiscoveryFeed(
          current: append ? _people : const [],
          incoming: people,
          dismissedIds: _dismissedUserIds,
        );
        _emptyReason = emptyReason;
        _nextReplayBefore = nextReplayBefore;
        if (nearby != null) {
          _nearby = nearby
              .where((p) => !_dismissedUserIds.contains(p.id))
              .toList();
        }
        _loadingPeople = false;
      });
      _prefetchDiscoveryPhotos();
      if (!append && _feedController.hasClients) {
        _feedController.jumpToPage(0);
      }
    } catch (error) {
      if (mounted && requestId == _peopleRequest) {
        _refresh(() {
          _loadingPeople = false;
          // A background failure must not hide cards that are still usable.
          if (!append || _people.isEmpty) _peopleError = error.toString();
        });
      }
    } finally {
      if (mounted && requestId == _peopleRequest) {
        _refillingPeople = false;
        if (_refillQueued) {
          _refillQueued = false;
          unawaited(_refillPeopleIfNeeded());
        }
      }
    }
  }

  Future<void> _selectTab(int index) async {
    if (_selectedTab == index) return;
    _refresh(() => _selectedTab = index);
    await _loadPeople();
  }
}
