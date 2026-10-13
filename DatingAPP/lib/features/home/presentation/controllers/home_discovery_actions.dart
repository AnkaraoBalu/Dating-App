part of '../screens/home_screen.dart';

extension _HomeDiscoveryActions on _HomeScreenState {
  List<String> get _activeInterests => <String?>[
    ..._filters.interests,
    _selectedInterest,
  ].whereType<String>().toList();

  Future<void> _recordActivity() async {
    try {
      await widget.discoverApi?.recordActivity();
    } catch (_) {}
  }

  Future<void> _loadPeople({bool nearbyAlso = true}) async {
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
      _loadingPeople = true;
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
        'radiusKm': _filters.radiusKm,
        'onlineOnly': _filters.onlineOnly,
        'verifiedOnly': _filters.verifiedOnly,
      };
      final peopleRequest = api.discover(
        mode: args['mode']! as String,
        minAge: args['minAge']! as int,
        maxAge: args['maxAge']! as int,
        gender: args['gender'] as String,
        location: args['location'] as String?,
        interest: args['interest'] as String?,
        interests: args['interests']! as List<String>,
        radiusKm: args['radiusKm']! as int,
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
              radiusKm: _filters.radiusKm,
              onlineOnly: _filters.onlineOnly,
              verifiedOnly: _filters.verifiedOnly,
            )
          : null;
      final results = await Future.wait([
        peopleRequest,
        ?nearbyRequest,
      ]);
      final people = results.first;
      final nearby = results.last;
      if (!mounted) return;
      _refresh(() {
        _people = people
            .where((p) => !_dismissedUserIds.contains(p.id))
            .toList();
        _nearby = nearby
            .where((p) => !_dismissedUserIds.contains(p.id))
            .toList();
        _loadingPeople = false;
      });
      if (_feedController.hasClients) _feedController.jumpToPage(0);
    } catch (error) {
      if (mounted) {
        _refresh(() {
          _loadingPeople = false;
          _peopleError = error.toString();
        });
      }
    }
  }

  Future<void> _selectTab(int index) async {
    if (_selectedTab == index) return;
    _refresh(() => _selectedTab = index);
    await _loadPeople();
  }
}
