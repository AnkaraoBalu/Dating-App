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
    if (_people.isNotEmpty && page >= _people.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _feedController.hasClients) {
          _feedController.jumpToPage(_people.length - 1);
        }
      });
    }
  }

  void _pass(HomePerson person) {
    if (person.id.isEmpty || widget.discoverApi == null) {
      _notice('Unable to save this pass right now.');
      _advanceFeed();
      return;
    }
    _removePerson(person);
    unawaited(() async {
      try {
        await widget.discoverApi!.pass(person.id);
      } catch (error) {
        if (mounted) {
          _dismissedUserIds.remove(person.id);
          _notice('Could not save your pass: $error');
          unawaited(_loadPeople(nearbyAlso: false));
        }
      }
    }());
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
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share profile'),
            onTap: () {
              Navigator.pop(sheetContext);
              _notice('Profile sharing is coming soon.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(sheetContext);
              _notice('Report options are coming soon.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: const Text('Not interested'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pass(person);
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _like(HomePerson person) async {
    if (_pendingLikeIds.contains(person.id)) return;
    if (person.id.isEmpty || widget.discoverApi == null) {
      _notice('Unable to send this like right now.');
      return;
    }
    _pendingLikeIds.add(person.id);
    _removePerson(person);
    try {
      final isMatch = await widget.discoverApi!.like(person.id);
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
        } else {
          _notice('You liked ${person.name} 💗');
        }
      }
    } catch (error) {
      if (mounted) {
        _dismissedUserIds.remove(person.id);
        _notice('Could not send like: $error');
        unawaited(_loadPeople(nearbyAlso: false));
      }
    } finally {
      _pendingLikeIds.remove(person.id);
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
