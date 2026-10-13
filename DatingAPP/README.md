# Just2

A clean Flutter starter for Android and iOS. The app opens to a welcome screen and a four-page introductory carousel, with responsive layout, safe areas, and large-text support. The Dart package is `dating_app`; `com.example` identifiers are development placeholders.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
flutter build ios --simulator
```

iOS builds require macOS and Xcode; Android builds require an Android SDK. Device/release iOS builds need your own Apple signing team. Set your final application ID, bundle ID, name, icons, and release signing before publishing.

## Structure

- `lib/main.dart`: entry point.
- `lib/app/`: application composition and navigation entry.
- `lib/core/constants/`: application name and shared copy.
- `lib/core/theme/`: shared colors and theme.
- `assets/images/`: runtime artwork, branding, and individual portrait images.
- `assets/source-images/`: preserved source collages and unused artwork; not bundled.
- `docs/design/`: visual reference and image generation prompts.
- `lib/features/welcome/presentation/screens/`: welcome and carousel screens.
- `lib/features/welcome/presentation/widgets/`: feature-specific UI.
- `test/`: startup and responsive welcome tests.
- `android/`, `ios/`: native mobile hosts.
- `web/`, `macos/`, `linux/`, `windows/`: retained Flutter hosts.

Add future features under `lib/features/<feature>/`, with `presentation/`, `domain/`, and `data/` only as needed. Reusable controls live in `lib/core/widgets/`. See [design system documentation](lib/core/theme/README.md) for theme tokens and usage.

The cloned transport screens, APIs, mock data, maps, calls, Firebase setup, and permissions have been removed. No backend, real authentication, matching, messaging, or notifications are configured yet. A three-screen [login UI preview](lib/features/login/README.md) is available. The welcome screen follows the reference with bundled sunset artwork, a dark photo overlay, editorial typography, and a reduced-motion-aware entrance animation. Get started opens the four-page carousel. It supports swipes, tappable dots, next/back controls, and reduced-motion-aware fade/scale transitions. The final action and sign-in open login choices, phone entry, and preview verification. Preview code: `123456`. No account is created. It requests no permissions.

Launcher icons and web favicon are resized from `assets/images/branding/logo.png` with `python3 tool/generate_app_icons.py` (uses macOS `sips`; no Python dependencies).

Validation: Flutter analysis and all twenty tests pass; Android ARM64 debug APK and iOS simulator builds pass. The default multi-architecture Android build needs the uncached x86_64 Flutter engine artifact, whose download stalled in this environment. Release signing and physical-device testing remain to be configured.

Asset workflow: check `assets/images/` for existing images first. The welcome background uses `assets/images/welcome/welcome_background.png`. Save newly created images into the project's asset folders before use, register their paths in `pubspec.yaml`, and reference them through `AppAssets`.

Carousel artwork is bundled in `assets/images/welcome/`. Exact generation prompts are recorded in [the artwork prompts](docs/design/welcome-image-prompts.md). Slide copy is centralized in `lib/features/welcome/data/welcome_slides.dart`.

App icon updates require a full rebuild/install (`flutter run`), not hot reload. Web favicon changes may require a hard browser refresh.
