part of '../screens/home_screen.dart';

// Restoring and saving discovery preferences, and the filter/category/travel pickers.
extension _HomePreferencesActions on _HomeScreenState {
  Future<void> _restorePreferences() async {
    HomeDiscoveryPreferences preferences;
    try {
      preferences = await _preferencesStore.load();
    } catch (error) {
      debugPrint('[HomePreferences] Could not load local preferences: $error');
      preferences = const HomeDiscoveryPreferences();
    }
    if (!mounted) return;
    _refresh(() {
      _filters = DiscoverFilterOptions(
        minAge: preferences.minAge,
        maxAge: preferences.maxAge,
        radiusKm: preferences.radiusKm,
        gender: preferences.gender,
        interest: preferences.interest,
        interests: preferences.interests,
        onlineOnly: preferences.onlineOnly,
        verifiedOnly: preferences.verifiedOnly,
      );
      _selectedVibeIds = preferences.selectedVibeIds;
      _selectedInterest = preferences.selectedInterest;
      _travelLocation = preferences.travelLocation;
      _preferencesReady = true;
    });
    await _loadPeople();
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesStore.save(
        HomeDiscoveryPreferences(
          selectedVibeIds: _selectedVibeIds,
          minAge: _filters.minAge,
          maxAge: _filters.maxAge,
          radiusKm: _filters.radiusKm,
          gender: _filters.gender,
          interest: _filters.interest,
          interests: _filters.interests,
          onlineOnly: _filters.onlineOnly,
          verifiedOnly: _filters.verifiedOnly,
          selectedInterest: _selectedInterest,
          travelLocation: _travelLocation,
        ),
      );
    } catch (error) {
      debugPrint('[HomePreferences] Could not save local preferences: $error');
    }
  }

  Future<void> _openFilters() async {
    final filters = await Navigator.of(context).push<DiscoverFilterOptions>(
      MaterialPageRoute(
        builder: (_) => DiscoverFiltersScreen(initial: _filters),
      ),
    );
    if (filters == null || !mounted) return;
    _refresh(() => _filters = filters);
    await _savePreferences();
    await _loadPeople();
  }

  Future<void> _openCategories() async {
    final interest = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DiscoverCategoriesScreen()),
    );
    if (interest == null || !mounted) return;
    _refresh(() {
      _selectedInterest = interest.isEmpty ? null : interest;
      _selectedTab = 0;
    });
    await _savePreferences();
    await _loadPeople();
  }

  Future<void> _openTravel() async {
    final city = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DiscoverTravelScreen()),
    );
    if (city == null || !mounted) return;
    _refresh(() {
      _travelLocation = city;
      _selectedTab = 0;
    });
    await _savePreferences();
    await _loadPeople();
  }
}
