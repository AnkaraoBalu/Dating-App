# Welcome feature

The app opens `WelcomeScreen`. Its default Get started action pushes `WelcomeCarouselScreen`, containing four pages. Four separate screen classes are unnecessary because the pages share the same layout.

```text
welcome/
  data/welcome_slides.dart              # Four slides' images, copy, and notes
  models/welcome_slide.dart             # Immutable slide model
  presentation/
    screens/
      welcome_screen.dart              # Photo landing screen and entry actions
      welcome_carousel_screen.dart     # PageController and navigation state
    widgets/
      welcome_actions.dart             # Landing actions
      welcome_brand.dart               # Logo, brand name, and opening copy
      welcome_illustration.dart        # Landing background and contrast overlay
      welcome_slide_artwork.dart       # Polaroid image and handwritten notes
      welcome_slide_page.dart          # Shared responsive page layout
      welcome_page_indicator.dart      # Accessible, tappable progress dots
      welcome_carousel_controls.dart   # Dots and next/finish action
```

Page content belongs in `WelcomeSlides`, not the screen. Shared theme values remain in `lib/core/theme/`. Asset paths are centralized in `AppAssets`; artwork lives in `assets/images/welcome/` and the logo in `assets/images/branding/`.

Keep app navigation state in screens and reusable visual composition in widgets. The carousel disposes its controller, allows swipe/dot/back navigation, and respects reduced motion. Content scrolls at large text sizes while navigation stays reachable.

The landing screen accepts `onGetStarted` and `onSignIn` callbacks. The carousel accepts `onComplete` for the future account flow; its default completion and sign-in behavior open `LoginScreen`.
