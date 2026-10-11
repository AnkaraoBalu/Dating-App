# Project structure

Flutter lives in `DatingAPP`; the NestJS API lives in `backend`. Organize each
feature by responsibility rather than putting the whole feature in one screen
or service file.

[SCREENS.md](SCREENS.md) is the map of every Flutter screen: the main user
flow, which file each screen lives in, what opens it, and which screens are
parked on purpose. Check it before looking for a screen, and update it whenever
you add, rename, move or re-link one.

## Flutter

- `models/`: data types and parsing, without HTTP requests or navigation.
- `data/`: authenticated API clients and state controllers shared by routes.
- `presentation/screens/`: route entry points, state ownership, lifecycle, and
  navigation into the feature. One screen per file, named after the screen
  class (`ConversationScreen` → `conversation_screen.dart`).
- `presentation/navigation/`: shared navigation helpers for a feature, such as
  `LoginRoutes` and `MatchNavigation`.
- `presentation/controllers/`: private flow action parts for existing wizards;
  these share their owning screen's state and call the feature's API client.
- `presentation/widgets/`: rendering, reusable components, and private layout
  parts belonging to a single screen. A part file is named after its screen
  (for example `matches_sections.dart` for `MatchesScreen`). Use independent widgets for components that
  need reuse across screens; do not import a `part` file directly.
- `core/widgets/`: components shared across features, such as
  `AdaptiveFlowColumn`. Keep feature-specific UI inside the feature.
- `core/realtime/`: `AuthedSocketConnection` (an authenticated Socket.IO
  connection that refreshes its token and reconnects) and the session-wide
  `RealtimeService` for inbox, like and match events. Feature live services,
  such as `vibes/data/vibe_room_live_service.dart`, build on
  `AuthedSocketConnection`. Chat screens still use their own conversation
  socket in `chat/data/`.

The onboarding, setup, and Home screens own their state; their layout and flow
actions are separated using Dart library parts, matching the existing setup
convention. Profile routes share a `ProfileController`. Keep HTTP and JSON
handling in `data`, and keep widget builders free of transport details.

Product areas with independent APIs and routes live in their own feature
folders: `chat/`, `matches/`, `vibes/`, and `profile/` (the user's own profile
and the Profile tab). `home/` holds the Home shell, its bottom tabs and
discovery, including other people's profiles. `profile_setup/` is for
onboarding and profile creation only. Cross-feature navigation should import a screen or
navigation helper from that feature, while each feature keeps its API clients in
`data/` and its screens under `presentation/screens/`.

Use safe areas, flexible text in rows, and scrollable content. Flow content is
centered with a maximum width of 640 logical pixels. On short screens, with the
keyboard open, or with larger text, the flow can scroll instead of overflowing.
Nested choice lists keep a bounded viewport. Do not disable accessibility text
scaling to hide overflow.

## Backend

- Controllers handle HTTP routing, authentication, request DTOs, and delegation.
- DTOs handle input validation and conversion.
- `ProfileRepository` handles authenticated user lookup and profile reads.
- `ProfileSetupService` coordinates editable details, prompts, and completion.
- `ProfileDiscoveryService` handles discovery queries, filtering, and ranking.
- `ProfilePhotosService` handles photo ownership, Cloudinary, photo limits, and
  ordering.
- `ProfileConnectionsService` handles persisted likes, reciprocal matches, and
  connection statistics.
- `RealtimeService` (global `realtime` module) sends live events to a member's
  private Socket.IO room; inject it instead of the messages gateway when a
  feature needs to notify users.
- `SendRateLimiter` (global `rate-limit` module) limits how fast a member can
  send messages; call `consume("<channel>:<userId>")` before saving a message.
- Register services through Nest dependency injection in their feature module.
- Database changes require a committed Prisma migration and regenerated client.

## Checks

Aim for focused files of roughly 300 lines or less. The structure check flags
application source files above 400 lines; split by responsibility rather than
moving arbitrary chunks solely to satisfy the limit. Generated code is excluded.
It also enforces the screen rules in [SCREENS.md](SCREENS.md): one screen per
file, named after the screen, under `presentation/screens/`, listed in the
screen map, and reachable from `main.dart` unless listed as parked.

Run from the workspace root:

```sh
python3 scripts/check_structure.py
```

Run Flutter analysis and the layout/behavior tests from `DatingAPP`:

```sh
flutter analyze --no-pub
flutter test --no-pub
```

Run backend checks from `backend`:

```sh
npm run backend:typecheck
npm run backend:test
```

Layout tests cover small phones, typical phones, and landscape with larger text.
They detect rendering errors and exercise setup navigation; they do not replace
visual review on actual devices or live API integration testing.
