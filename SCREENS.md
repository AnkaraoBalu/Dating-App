# Screen map

Every screen in the Flutter app, where its code lives, and how users reach it.
Paths are relative to `DatingAPP/lib/features/`. `python3 scripts/check_structure.py`
fails if a screen is missing from this file, if a screen file breaks the naming
rules below, or if a screen can't be reached from app start and isn't listed
under [Parked screens](#parked-screens).

## Rules for screens

1. **One screen per file.** A screen is a public widget class ending in
   `Screen`, `Viewer` or `Gate` (a route the user navigates to).
2. **The file is named after the screen.** `ConversationScreen` lives in
   `conversation_screen.dart`.
3. **Screens live in `<feature>/presentation/screens/`.** Pieces that only one
   screen uses go in `presentation/widgets/` (layout) or
   `presentation/controllers/` (actions), as `part` files of that screen or as
   standalone widgets.
4. **The feature folder is the product area the user sees.** If you're looking
   for the chat list, it's in `chat/`; the user's own profile is in
   `profile/`; other people's profiles shown during discovery are in `home/`.
5. **When you add, rename or remove a screen, update this file** in the same
   change: the flow diagram if the main path changes, and the feature table.

## Main flow

```
App start (lib/app/dating_app.dart)
├─ Signed out → WelcomeScreen ─→ WelcomeCarouselScreen ─→ LoginScreen
│                 └──────────────────────────────────────→ LoginScreen
│     LoginScreen ─→ EmailLoginScreen ─→ VerifyClerkCodeScreen ─┐
│                 └→ DemoLoginScreen (debug builds) ────────────┤
│                    Google sign-in (Clerk OAuth deep link) ────┤
│                                                               ▼
└─ Signed in → SignedInGate  (picks the first unfinished step)
      ├─ New user:         LocationScreen ─→ OnboardingQuestionsScreen
      │                       ─→ OnboardingCompleteScreen ─→ ProfileSetupScreen
      │                       (─→ ProfileBasicsScreen) ─→ HomeScreen
      ├─ Onboarding done:  OnboardingCompleteScreen ─→ ProfileSetupScreen ─→ HomeScreen
      └─ Setup done:       HomeScreen

HomeScreen bottom tabs
├─ Discover  swipe feed inside HomeScreen; filters, categories, travel, map,
│            people grids → ProfileQuickPreviewScreen → ProfileDetailScreen
├─ Vibes     VibeRoomsHomeScreen (rooms) · "Explore people" → VibeExploreScreen
├─ Matches   MatchesScreen → ConversationScreen · LikesReceivedScreen
├─ Chat      ChatsScreen → ConversationScreen → ChatInfoScreen / MatchedProfileScreen
└─ Profile   ProfileMainScreen → edit, photos, preview, insights, settings, verification

A mutual like anywhere shows MatchCelebrationScreen
(matches/presentation/navigation/match_navigation.dart)
  → ConversationScreen ("Send a message") or MatchedProfileScreen ("View profile").
```

The bottom tabs are not pushed routes: `HomeScreen` switches between
`VibeRoomsHomeScreen`, `MatchesScreen`, `ChatsScreen` and `ProfileMainScreen`
inside its own body, so those screens show "HomeScreen" as their opener below.

## Screens by feature

"Opened from" and "Leads to" list the screens (or helpers) whose code navigates
there. They are generated from the code, so regenerate them when navigation
changes instead of editing them by hand.

### `welcome/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| WelcomeCarouselScreen | `welcome_carousel_screen.dart` | WelcomeScreen | LoginScreen |
| WelcomeScreen | `welcome_screen.dart` | App start | LoginScreen, WelcomeCarouselScreen |

### `login/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| EmailLoginScreen | `email_login_screen.dart` | LoginScreen | VerifyClerkCodeScreen |
| LocationScreen | `location_screen.dart` | SignedInGate | — |
| LoginScreen | `login_screen.dart` | WelcomeCarouselScreen, WelcomeScreen | DemoLoginScreen, EmailLoginScreen |
| PhoneLoginScreen | `phone_login_screen.dart` | — | VerifyClerkCodeScreen |
| SignedInGate | `signed_in_gate.dart` | App start | HomeScreen, LocationScreen, OnboardingCompleteScreen, OnboardingQuestionsScreen |
| VerifyClerkCodeScreen | `verify_clerk_code_screen.dart` | EmailLoginScreen, PhoneLoginScreen | — |
| VerifyPhoneScreen | `verify_phone_screen.dart` | — | — |

### `demo_auth/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| DemoLoginScreen | `demo_login_screen.dart` | LoginScreen | — |

### `onboarding/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| OnboardingCompleteScreen | `onboarding_complete_screen.dart` | OnboardingQuestionsScreen, SignedInGate | ProfileSetupScreen |
| OnboardingQuestionsScreen | `onboarding_questions_screen.dart` | SignedInGate | OnboardingCompleteScreen |

### `profile_setup/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| ProfileBasicsScreen | `profile_basics_screen.dart` | ProfileSetupScreen | — |
| ProfileSetupScreen | `profile_setup_screen.dart` | OnboardingCompleteScreen | HomeScreen, ProfileBasicsScreen |

### `home/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| DiscoverCategoriesScreen | `discover_categories_screen.dart` | HomeScreen | — |
| DiscoverFiltersScreen | `discover_filters_screen.dart` | HomeScreen, VibeFeedScreen | — |
| DiscoverMapScreen | `discover_map_screen.dart` | DiscoverPeopleScreen, HomeScreen | ProfileQuickPreviewScreen |
| DiscoverPeopleScreen | `discover_people_screen.dart` | HomeScreen, VibeExploreScreen, VibeSearchScreen | DiscoverMapScreen, ProfileQuickPreviewScreen |
| DiscoverTravelScreen | `discover_travel_screen.dart` | HomeScreen, VibeSearchScreen | — |
| HomeScreen | `home_screen.dart` | ProfileSetupScreen, SignedInGate | ChatsScreen, DiscoverCategoriesScreen, DiscoverFiltersScreen, DiscoverMapScreen, DiscoverPeopleScreen, DiscoverTravelScreen, LikesReceivedScreen, MatchesScreen, ProfileMainScreen, ProfileQuickPreviewScreen, VibeExploreScreen, VibeRoomsHomeScreen |
| ProfileDetailScreen | `profile_detail_screen.dart` | ProfileQuickPreviewScreen, VibeFeedScreen | — |
| ProfileQuickPreviewScreen | `profile_quick_preview_screen.dart` | DiscoverMapScreen, DiscoverPeopleScreen, HomeScreen, LikesReceivedScreen, VibeFeedScreen, VibeSearchScreen | ProfileDetailScreen |

### `vibes/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| CreateVibeRoomScreen | `create_vibe_room_screen.dart` | VibeCategoryRoomsScreen, VibeRoomsHomeScreen | RoomDetailScreen |
| GameResultsScreen | `game_results_screen.dart` | LiveVibeGameScreen | LiveVibeRoomScreen |
| IcebreakerGamesScreen | `icebreaker_games_screen.dart` | LiveVibeRoomScreen | LiveVibeGameScreen |
| LiveVibeGameScreen | `live_vibe_game_screen.dart` | IcebreakerGamesScreen | GameResultsScreen |
| LiveVibeRoomScreen | `live_vibe_room_screen.dart` | GameResultsScreen, MyVibeRoomsScreen, RoomDetailScreen | IcebreakerGamesScreen, LiveVibeVoiceScreen, VibeRoomPeopleScreen |
| LiveVibeVoiceScreen | `live_vibe_voice_screen.dart` | LiveVibeRoomScreen | — |
| MyVibeRoomsScreen | `my_vibe_rooms_screen.dart` | VibeRoomsHomeScreen | LiveVibeRoomScreen, RoomDetailScreen, RoomSettingsScreen |
| RoomDetailScreen | `room_detail_screen.dart` | CreateVibeRoomScreen, MyVibeRoomsScreen, SavedVibeRoomsScreen, VibeCategoryRoomsScreen, VibeRoomsHomeScreen | LiveVibeRoomScreen, VibeRoomPeopleScreen |
| RoomSettingsScreen | `room_settings_screen.dart` | MyVibeRoomsScreen | — |
| SavedVibeRoomsScreen | `saved_vibe_rooms_screen.dart` | VibeRoomsHomeScreen | RoomDetailScreen |
| TrendingVibesScreen | `trending_vibes_screen.dart` | VibeExploreScreen | VibeFeedScreen |
| VibeCategoryRoomsScreen | `vibe_category_rooms_screen.dart` | VibeRoomCategoriesScreen | CreateVibeRoomScreen, RoomDetailScreen |
| VibeExploreScreen | `vibe_explore_screen.dart` | HomeScreen | DiscoverPeopleScreen, TrendingVibesScreen, VibeFeedScreen, VibeSearchScreen, VibeSelectionScreen |
| VibeFeedScreen | `vibe_feed_screen.dart` | TrendingVibesScreen, VibeExploreScreen, VibeSearchScreen | DiscoverFiltersScreen, ProfileDetailScreen, ProfileQuickPreviewScreen |
| VibeRoomCategoriesScreen | `vibe_room_categories_screen.dart` | VibeRoomsHomeScreen | VibeCategoryRoomsScreen |
| VibeRoomPeopleScreen | `vibe_room_people_screen.dart` | LiveVibeRoomScreen, RoomDetailScreen | VibeRoomProfileScreen |
| VibeRoomProfileScreen | `vibe_room_profile_screen.dart` | VibeRoomPeopleScreen | — |
| VibeRoomsHomeScreen | `vibe_rooms_home_screen.dart` | HomeScreen | CreateVibeRoomScreen, MyVibeRoomsScreen, RoomDetailScreen, SavedVibeRoomsScreen, VibeRoomCategoriesScreen |
| VibeSearchScreen | `vibe_search_screen.dart` | VibeExploreScreen | DiscoverPeopleScreen, DiscoverTravelScreen, ProfileQuickPreviewScreen, VibeFeedScreen |
| VibeSelectionScreen | `vibe_selection_screen.dart` | VibeExploreScreen | — |

### `matches/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| LikesReceivedScreen | `likes_received_screen.dart` | HomeScreen, MatchesScreen | ProfileQuickPreviewScreen |
| MatchCelebrationScreen | `match_celebration_screen.dart` | match celebration helper | ConversationScreen, MatchedProfileScreen |
| MatchedProfileScreen | `matched_profile_screen.dart` | ConversationScreen, MatchCelebrationScreen | ConversationScreen |
| MatchesScreen | `matches_screen.dart` | HomeScreen | ConversationScreen, LikesReceivedScreen |

### `chat/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| ChatImageViewer | `chat_image_viewer.dart` | SharedMediaScreen, chat photos | — |
| ChatInfoScreen | `chat_info_screen.dart` | ConversationScreen | ChatSearchScreen, SharedMediaScreen |
| ChatSearchScreen | `chat_search_screen.dart` | ChatInfoScreen, ConversationScreen | — |
| ChatsScreen | `chats_screen.dart` | HomeScreen | ConversationScreen |
| ConversationScreen | `conversation_screen.dart` | ChatsScreen, MatchCelebrationScreen, MatchedProfileScreen, MatchesScreen | ChatInfoScreen, ChatSearchScreen, MatchedProfileScreen, SharedMediaScreen |
| SharedMediaScreen | `shared_media_screen.dart` | ChatInfoScreen, ConversationScreen | ChatImageViewer |

### `profile/`

| Screen | File (`presentation/screens/`) | Opened from | Leads to |
|---|---|---|---|
| GuidedSelfieCaptureScreen | `guided_selfie_capture_screen.dart` | — | — |
| ProfileAboutMeScreen | `profile_about_me_screen.dart` | ProfileEducationWorkScreen | ProfileInterestsScreen |
| ProfileBasicInfoScreen | `profile_basic_info_screen.dart` | — | ProfileEducationWorkScreen |
| ProfileEditScreen | `profile_edit_screen.dart` | Profile ⋯ menu, ProfileMainScreen, ProfileSettingsScreen | ProfilePhotoGalleryScreen |
| ProfileEducationWorkScreen | `profile_education_work_screen.dart` | ProfileBasicInfoScreen | ProfileAboutMeScreen |
| ProfileInsightsScreen | `profile_insights_screen.dart` | ProfileMainScreen | — |
| ProfileInterestsScreen | `profile_interests_screen.dart` | ProfileAboutMeScreen | ProfileMoreDetailsScreen |
| ProfileMainScreen | `profile_main_screen.dart` | HomeScreen | ProfileEditScreen, ProfileInsightsScreen, ProfilePhotoGalleryScreen, ProfilePreviewScreen, ProfileSettingsScreen, ProfileVerificationScreen |
| ProfileMoreDetailsScreen | `profile_more_details_screen.dart` | ProfileInterestsScreen | ProfilePreviewScreen |
| ProfilePhotoEditScreen | `profile_photo_edit_screen.dart` | ProfilePhotoGalleryScreen | — |
| ProfilePhotoGalleryScreen | `profile_photo_gallery_screen.dart` | ProfileEditScreen, ProfileMainScreen | ProfilePhotoEditScreen |
| ProfilePreviewScreen | `profile_preview_screen.dart` | Profile ⋯ menu, ProfileMainScreen, ProfileMoreDetailsScreen | — |
| ProfilePrivacyScreen | `profile_privacy_screen.dart` | ProfileSettingsScreen | — |
| ProfileSettingsScreen | `profile_settings_screen.dart` | ProfileMainScreen | ProfileEditScreen, ProfilePrivacyScreen, ProfileVerificationScreen |
| ProfileVerificationScreen | `profile_verification_screen.dart` | ProfileMainScreen, ProfileSettingsScreen | — |

## Parked screens

These screens are not reachable from app start on purpose. Keep them out of
navigation until the listed condition is met, then wire them in and move them
into the main flow above.

| Screen | Why it's parked | To activate |
|---|---|---|
| `login/` PhoneLoginScreen | Phone sign-in is hidden until Clerk SMS is set up (see `login/README.md`). | Enable phone sign-in and SMS countries in Clerk, then add a "Continue with phone" button to `LoginScreen`. It already sends codes through `VerifyClerkCodeScreen`. |
| `login/` VerifyPhoneScreen | Earlier preview of phone verification; superseded by `VerifyClerkCodeScreen`. | Remove it when phone sign-in is activated. |
| `profile/` GuidedSelfieCaptureScreen | Camera-only prototype: it takes selfies but never uploads them. Verification uses FaceTec in `ProfileVerificationScreen`. | Add an upload/review API first; then it could serve as the fallback when FaceTec is unavailable. |
| `profile/` ProfileBasicInfoScreen → ProfileEducationWorkScreen → ProfileAboutMeScreen → ProfileInterestsScreen → ProfileMoreDetailsScreen | The old step-by-step profile editor. Replaced by the section list in `ProfileEditScreen`, which edits the same fields. | Not planned. Delete once nothing depends on it (`test/profile_management_test.dart` still uses some of these screens directly). |

## Actions that aren't built yet

These buttons are visible but show a "coming soon" message instead of
navigating anywhere. Each one needs backend support first.

| Where | Action |
|---|---|
| HomeScreen person menu | Share profile, Report |
| Home explore section | Matchify+ |
| ConversationScreen | Voice call, GIF search, Clear chat |
| ChatInfoScreen | Audio call, Video call, Mute, Block, Report |
| MatchedProfileScreen | ⋯ menu (unmatch, report) |
| ProfileSetupScreen | Spotify connection |

## Adding a screen

1. Create `<feature>/presentation/screens/<name>_screen.dart` with one public
   `<Name>Screen` class.
2. Navigate to it from an existing screen. Use the feature's navigation helper
   if it has one (`login/presentation/navigation/login_routes.dart`,
   `matches/presentation/navigation/match_navigation.dart`).
3. Add it to the flow diagram (if it's on the main path) and to its feature table.
4. Run `python3 scripts/check_structure.py` from the workspace root.


## Public website (`frontend/`)

The React website introduces the mobile app; the Flutter screen rules above
apply to `DatingAPP`, while the web component conventions are documented in
[frontend/ARCHITECTURE.md](frontend/ARCHITECTURE.md).

| URL | Page | File relative to frontend/src | Navigation |
| --- | --- | --- | --- |
| `/` | HomePage | `app/home/HomePage.tsx` | Story, walkthrough, demos, app CTA |
| `/about` | AboutPage | `app/about/AboutPage.tsx` | Our story and values |
| `/how-it-works` | HowItWorksPage | `app/how-it-works/HowItWorksPage.tsx` | Product walkthrough and Help |
| `/vibes` | VibesPage | `app/vibes/VibesPage.tsx` | Filterable illustrative themes |
| `/help` | HelpPage | `app/help/HelpPage.tsx` | Search, categories, accordions; `#chat` deep link |
| `/download` | DownloadPage | `app/download/DownloadPage.tsx` | App availability and chat demo |
| `/community-guidelines` | CommunityPage | `app/community-guidelines/CommunityPage.tsx` | Community principles |
| `/privacy` | PrivacyPage | `app/privacy/PrivacyPage.tsx` | Pending final privacy document |
| `/terms` | TermsPage | `app/terms/TermsPage.tsx` | Pending final terms document |
| `*` | NotFoundPage | `app/not-found/NotFoundPage.tsx` | Return to Home |

`WebsiteLayout` provides the shared Navbar and Footer, page titles, focus and
scroll handling. Mobile navigation is a fullscreen modal dialog. The desktop
sticky story becomes stacked content on mobile and with reduced motion.
Matching and chat demos use local illustrative state. Store links and final
privacy/terms documents must be supplied before publishing.
