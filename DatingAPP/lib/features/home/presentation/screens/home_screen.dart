import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/home_discover_data.dart';
import '../../data/discover_api.dart';
import '../../data/home_discovery_preferences.dart';
import '../../../profile/data/profile_controller.dart';
import '../../../profile/presentation/screens/profile_main_screen.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart'
    show ProfilePhotoView;
import 'discover_categories_screen.dart';
import 'discover_filters_screen.dart';
import 'discover_map_screen.dart';
import 'discover_people_screen.dart';
import 'discover_travel_screen.dart';
import 'profile_quick_preview_screen.dart';
import '../widgets/home_discover_sections.dart';
import '../widgets/home_tab_placeholder.dart';
import '../../../matches/presentation/screens/matches_screen.dart';
import '../../../matches/data/match_controller.dart';
import '../../../matches/data/match_api.dart';
import '../../../chat/presentation/screens/chats_screen.dart';
import '../../../chat/data/chat_api.dart';
import '../../../matches/presentation/screens/likes_received_screen.dart';
import '../../../matches/presentation/navigation/match_navigation.dart';
import '../../../vibes/presentation/screens/vibe_explore_screen.dart';
import '../../../vibes/presentation/screens/vibe_rooms_home_screen.dart';
import '../../../vibes/data/vibe_rooms_api.dart';
import '../widgets/home_person_card.dart';
import '../../../../core/realtime/realtime_service.dart';

part '../controllers/home_discovery_actions.dart';
part '../widgets/home_feed_layout.dart';
part '../widgets/home_header_filters.dart';
part '../widgets/home_people_sections.dart';
part '../widgets/home_explore_sections.dart';
part '../widgets/home_bottom_navigation.dart';
part '../controllers/home_person_actions.dart';
part '../controllers/home_preferences_actions.dart';
part '../controllers/home_realtime_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.displayName,
    this.discoverApi,
    this.location,
    this.photos = const [],
    this.bio = '',
    this.fieldOfStudy,
  });

  final String displayName;
  final DiscoverApi? discoverApi;
  final String? location;
  final List<String> photos;
  final String bio;
  final String? fieldOfStudy;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = ['For You', 'Nearby', 'Trending'];
  static const _navLabels = ['Discover', 'Vibes', 'Matches', 'Chat', 'Profile'];
  static const _navIcons = [
    Icons.home_rounded,
    Icons.auto_awesome_rounded,
    Icons.favorite_border_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];
  static const _selectedNavIcons = [
    Icons.home_rounded,
    Icons.auto_awesome_rounded,
    Icons.favorite_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];
  int _selectedTab = 0;
  int _selectedNav = 0;
  bool _liked = false;
  final Set<String> _dismissedUserIds = {};
  final Set<String> _pendingLikeIds = {};
  bool _loadingPeople = true;
  String? _peopleError;
  List<HomePerson> _people = const [];
  List<HomePerson> _nearby = const [];
  DiscoverFilterOptions _filters = const DiscoverFilterOptions();
  Set<String> _selectedVibeIds = {};
  String? _selectedInterest;
  String? _travelLocation;
  final HomeDiscoveryPreferencesStore _preferencesStore =
      HomeDiscoveryPreferencesStore();
  bool _preferencesReady = false;
  Timer? _activityTimer;
  Timer? _matchRefreshTimer;
  ProfileController? _profileController;
  MatchController? _matchController;
  RealtimeService? _realtime;
  StreamSubscription<RealtimeEvent>? _realtimeEvents;
  Timer? _realtimeReload;
  String? _pendingMatchAnnouncement;
  final PageController _feedController = PageController();

  int get _unreadChatCount =>
      _matchController?.matches.fold<int>(
        0,
        (total, match) => total + match.unreadCount,
      ) ??
      0;

  List<HomePerson> get _feedPeople => _people;
  String? get _memberLocation =>
      _profileController?.profile?.text('location') ?? widget.location;
  List<String> get _memberPhotos =>
      _profileController?.profile?.photos.map((p) => p.url).toList() ??
      widget.photos;
  void _profileUpdated() {
    if (mounted) setState(() {});
  }

  void _refresh(VoidCallback mutation) => setState(mutation);

  Future<void> _openLikes() async {
    unawaited(_matchController?.loadIncomingLikes());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LikesReceivedScreen(
          controller: _matchController!,
          currentUserImage: _memberPhotos.isEmpty ? null : _memberPhotos.first,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _matchesUpdated() {
    if (mounted) setState(() {});
  }

  void _discoverLikesUpdated() {
    if (!mounted) return;
    final api = widget.discoverApi;
    final liked = {
      ..._people,
      ..._nearby,
    }.where((p) => api?.hasLiked(p.id) == true).toList();
    for (final person in liked) {
      _removePerson(person);
    }
    unawaited(_matchController?.load());
  }

  @override
  void initState() {
    super.initState();
    final api = widget.discoverApi;
    if (api != null) {
      api.addListener(_discoverLikesUpdated);
      _matchController = MatchController(
        discoverApi: api,
        api: MatchApi(
          baseUrl: api.baseUrl,
          getSessionToken: api.getSessionToken,
        ),
      )..load();
      _profileController = ProfileController(
        baseUrl: api.baseUrl,
        getSessionToken: api.getSessionToken,
      );
      _profileController!.addListener(_profileUpdated);
      _profileController!.load();
    } else {
      _matchController = MatchController(
        api: MatchApi(baseUrl: '', getSessionToken: () async => ''),
      );
    }
    _matchController?.addListener(_matchesUpdated);
    if (api != null) {
      _startRealtime(api);
      // Fallback while the live connection is down.
      _matchRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_realtime?.connected.value != true) {
          unawaited(_matchController?.load());
        }
      });
    }
    unawaited(_restorePreferences());
    _recordActivity();
    _activityTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _recordActivity(),
    );
  }

  @override
  void dispose() {
    widget.discoverApi?.removeListener(_discoverLikesUpdated);
    _profileController?.removeListener(_profileUpdated);
    _matchController?.removeListener(_matchesUpdated);
    _matchController?.dispose();
    _profileController?.dispose();
    _activityTimer?.cancel();
    _matchRefreshTimer?.cancel();
    _stopRealtime();
    _feedController.dispose();
    super.dispose();
  }

  void _advanceFeed() {
    if (!_feedController.hasClients || _feedPeople.isEmpty) return;
    final next = _feedController.page!.round() + 1;
    _feedController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _openPeople(DiscoverPeopleMode mode) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DiscoverPeopleScreen(
        mode: mode,
        api: widget.discoverApi,
        location: _travelLocation ?? widget.location,
        filters: _filters,
        interest: _selectedInterest,
      ),
    ),
  );

  void _openPreview(HomePerson person) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ProfileQuickPreviewScreen(person: person, api: widget.discoverApi),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedNav),
                    child: !_preferencesReady
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.coral,
                            ),
                          )
                        : _selectedNav == 0
                        ? _discover()
                        : _selectedNav == 1
                        ? VibeRoomsHomeScreen(
                            api: widget.discoverApi == null
                                ? null
                                : VibeRoomsApi(
                                    baseUrl: widget.discoverApi!.baseUrl,
                                    getSessionToken:
                                        widget.discoverApi!.getSessionToken,
                                  ),
                            onOpenLikes: _openLikes,
                            onOpenProfile: () =>
                                _refresh(() => _selectedNav = 4),
                            currentUserImage: _memberPhotos.isEmpty
                                ? null
                                : _memberPhotos.first,
                            onExplorePeople: () =>
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => VibeExploreScreen(
                                      api: widget.discoverApi,
                                      filters: _filters,
                                      onFiltersChanged: (filters) {
                                        _refresh(() => _filters = filters);
                                        unawaited(_savePreferences());
                                        unawaited(_loadPeople());
                                      },
                                      location: _memberLocation,
                                      selectedVibeIds: _selectedVibeIds,
                                      onSelectionChanged: (ids) {
                                        _refresh(() => _selectedVibeIds = ids);
                                        unawaited(_savePreferences());
                                      },
                                      onOpenLikes: _openLikes,
                                      onOpenProfile: () =>
                                          _refresh(() => _selectedNav = 4),
                                      onMatch: () =>
                                          unawaited(_matchController?.load()),
                                      currentUserImage: _memberPhotos.isEmpty
                                          ? null
                                          : _memberPhotos.first,
                                      currentUserName: widget.displayName,
                                    ),
                                  ),
                                ),
                          )
                        : _selectedNav == 4
                        ? ProfileMainScreen(controller: _profileController)
                        : _selectedNav == 2
                        ? MatchesScreen(
                            controller: _matchController!,
                            onExplorePeople: () =>
                                _refresh(() => _selectedNav = 0),
                            currentUserImage: _memberPhotos.isEmpty
                                ? null
                                : _memberPhotos.first,
                          )
                        : _selectedNav == 3
                        ? ChatsScreen(controller: _matchController!)
                        : HomeTabPlaceholder(
                            tab: _navLabels[_selectedNav],
                            icon: _navIcons[_selectedNav],
                          ),
                  ),
                ),
              ),
              _bottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}
