# Just2 design system

The palette and typography follow [the screen reference](../../../docs/design/All_Screens.png) and the supplied design notes. Screens consume `Theme.of(context)` and shared widgets, rather than defining their own colors and control styles.

## Tokens

| File | Purpose |
| --- | --- |
| `app_colors.dart` | Forest `#173F35`, coral `#FF6678`, peach `#FFC8A8`, ivory `#FFF9EF`, surfaces, text, borders, status colors |
| `app_typography.dart` | DM Serif Display headings, Manrope UI; 11–42 point scale |
| `app_spacing.dart` | 4, 8, 12, 16, 20, 24, 32, 40, 48 |
| `app_radius.dart` | 8, 12, 16, 20, 28, pill |
| `app_sizes.dart` | Control minimum sizes and icon sizes |
| `app_gradients.dart` | Match, sunset, forest, photo overlay |
| `app_motion.dart` | Timing, curves, reduced-motion support |
| `app_shadows.dart` | Subtle card and coral action shadows |
| `app_theme.dart` | Light/dark Material themes and component defaults |

Font files and their OFL licenses are bundled under `assets/fonts/`; no network font loading is needed. Styles inherit theme text colors. Coral buttons use dark foreground text for readability. Controls use minimum heights and grow with larger text rather than clipping to fixed heights.

## Shared components

`lib/core/widgets/` contains buttons (primary, love, secondary, circular actions), interest/selection/vibe chips, selection/profile/vibe cards, text fields, verification/vibe badges, progress, four-tab navigation, empty states, and loading placeholders. Import `core/widgets/widgets.dart` for the full collection or individual files.

```dart
PrimaryButton(label: 'Continue', onPressed: onContinue);
LoveButton(label: 'Send a vibe', onPressed: onSend);
SelectionChip(label: 'Coffee', selected: likesCoffee, onSelected: onCoffeeChanged);
AppTextField(label: 'Your name', controller: nameController);
```

Selection state and callbacks belong to the feature. Null callbacks disable controls; `isLoading` blocks duplicate button presses. Inputs work inside a `Form`. Circular actions require a tooltip for accessibility. Pass image widgets into photo cards; data fetching belongs to features.

Utility screens use `AppTheme.light`. Wrap immersive/photo screens in `Theme(data: AppTheme.dark, child: ...)`. Both themes are registered in the app; the current welcome uses a local dark theme. Use `textTheme.displayMedium` for editorial hero copy and `bodyMedium` for functional text. Chips should be placed in `Wrap` to handle narrow screens.

The reference image remains design documentation and is not bundled as a runtime asset. This adds reusable UI foundations; it does not implement auth, matching, chat, or the other reference screens.
