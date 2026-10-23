part of '../screens/home_screen.dart';

// Like, pass, per-person actions and the map for the discovery feed.
extension _HomePersonActions on _HomeScreenState {
  void _removePerson(HomePerson person) {
    final page = _feedController.hasClients
        ? (_feedController.page ?? 0).round()
        : 0;
    _refresh(() {
      _dismissedUserIds.add(person.id);
      _people = _people.where((item) => item.id != person.id).toList();
      _nearby = _nearby.where((item) => item.id != person.id).toList();
    });
    _prefetchDiscoveryPhotos();
    if (_people.isNotEmpty && page >= _people.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _feedController.hasClients) {
          _feedController.jumpToPage(_people.length - 1);
        }
      });
    }
  }

  void _restoreFailedSwipe(
    HomePerson person,
    int index,
    DiscoverFilterOptions filters,
    int tab,
    String? travel,
    String? interest,
  ) {
    if (!mounted || _safetyDismissedIds.contains(person.id)) return;
    _refresh(() {
      _dismissedUserIds.remove(person.id);
      if (identical(_filters, filters) &&
          _selectedTab == tab &&
          _travelLocation == travel &&
          _selectedInterest == interest) {
        _people = restoreDiscoveryCard(_people, person, index);
        _peopleError = null;
      }
    });
    _prefetchDiscoveryPhotos();
  }

  void _pass(HomePerson person) {
    if (_pendingLikeIds.contains(person.id) ||
        _pendingPassIds.contains(person.id) ||
        _dismissedUserIds.contains(person.id)) {
      return;
    }
    if (person.id.isEmpty || widget.discoverApi == null) {
      _notice('Unable to save this pass right now.');
      return;
    }
    if (!_pendingPassIds.add(person.id)) return;
    final index = _people.indexWhere((card) => card.id == person.id);
    final filters = _filters;
    final tab = _selectedTab;
    final travel = _travelLocation;
    final interest = _selectedInterest;
    _removePerson(person);
    unawaited(() async {
      try {
        await widget.discoverApi!.pass(person.id);
        _passedUserIds.add(person.id);
        await _refillPeopleIfNeeded();
      } catch (error) {
        if (mounted) {
          _restoreFailedSwipe(person, index, filters, tab, travel, interest);
          _notice(
            'Could not save your pass. Your card is available to try again.',
          );
        }
      } finally {
        _pendingPassIds.remove(person.id);
        if (mounted) _refresh(() {});
      }
    }());
  }

  SafetyApi? get _safetyApi {
    final api = widget.discoverApi;
    return api == null
        ? null
        : SafetyApi(baseUrl: api.baseUrl, getSessionToken: api.getSessionToken);
  }

  Future<void> _blockPerson(HomePerson person) async {
    final api = _safetyApi;
    if (api == null || person.id.isEmpty) return;
    if (await confirmAndBlock(
          context,
          api: api,
          userId: person.id,
          name: person.name,
        ) &&
        mounted) {
      _safetyDismissedIds.add(person.id);
      _removePerson(person);
    }
  }

  Future<void> _reportPerson(HomePerson person) async {
    final api = _safetyApi;
    if (api == null || person.id.isEmpty) return;
    if (await showReportFlow(
          context,
          api: api,
          userId: person.id,
          name: person.name,
          source: 'discover',
        ) &&
        mounted) {
      _safetyDismissedIds.add(person.id);
      _removePerson(person);
    }
  }

  void _showActions(HomePerson person) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('View full profile'),
            onTap: () {
              Navigator.pop(sheetContext);
              _openPreview(person);
            },
          ),
          ListTile(
            leading: const Icon(Icons.thumb_down_alt_outlined),
            title: const Text('Not interested'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pass(person);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: AppColors.error),
            title: Text(
              'Block ${person.name}',
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              unawaited(_blockPerson(person));
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.error),
            title: Text(
              'Report ${person.name}',
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              unawaited(_reportPerson(person));
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _like(HomePerson person) async {
    if (_pendingLikeIds.contains(person.id) ||
        _pendingPassIds.contains(person.id) ||
        _dismissedUserIds.contains(person.id)) {
      return;
    }
    if (person.id.isEmpty || widget.discoverApi == null) {
      _notice('Unable to send this like right now.');
      return;
    }
    _pendingLikeIds.add(person.id);
    final index = _people.indexWhere((card) => card.id == person.id);
    final filters = _filters;
    final tab = _selectedTab;
    final travel = _travelLocation;
    final interest = _selectedInterest;
    var saved = false;
    _removePerson(person);
    try {
      final isMatch = await widget.discoverApi!.like(person.id);
      saved = true;
      if (mounted) {
        if (isMatch) {
          await MatchNavigation.celebrate(
            context,
            person: person,
            chatApi: ChatApi(
              baseUrl: widget.discoverApi!.baseUrl,
              getSessionToken: widget.discoverApi!.getSessionToken,
            ),
            currentUserImage: _memberPhotos.isEmpty
                ? null
                : _memberPhotos.first,
            currentUserName: widget.displayName,
          );
          if (mounted) await _matchController?.load();
        }
      }
    } catch (error) {
      if (mounted) {
        if (saved) {
          _notice('Your like was saved. Open Matches to continue.');
        } else {
          _restoreFailedSwipe(person, index, filters, tab, travel, interest);
          _notice(
            'Could not send your like. Your card is available to try again.',
          );
        }
      }
    } finally {
      _pendingLikeIds.remove(person.id);
      unawaited(_refillPeopleIfNeeded());
    }
  }

  Future<void> _openMap() async {
    try {
      final people =
          await widget.discoverApi?.discover(
            mode: 'nearby',
            minAge: _filters.minAge,
            maxAge: _filters.maxAge,
            gender: _filters.gender,
            radiusKm: _filters.radiusKm,
            location: _travelLocation,
            interest: _selectedInterest ?? _filters.interest,
            onlineOnly: _filters.onlineOnly,
            verifiedOnly: _filters.verifiedOnly,
          ) ??
          const <HomePerson>[];
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              DiscoverMapScreen(people: people, api: widget.discoverApi),
        ),
      );
    } catch (error) {
      if (mounted) _notice('Could not load the map: $error');
    }
  }
}
