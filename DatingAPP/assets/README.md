# Asset structure

- `images/branding/logo.png`: cropped logo used in welcome/login and as the source for launcher icons and web favicon.
- `images/login/ambient_bokeh.png`: generated photographic login header; prompt under `docs/design/`.
- `images/welcome/welcome_background.png`: existing user-provided welcome background, restored from its build copy after the original asset folder was moved.
- `images/welcome/*_polaroids.png`: four generated carousel artworks.
- `images/girls-images/`, `images/boys-images/`: individual sample portraits; selected files are bundled. Do not use them as activity imagery or as substitutes for missing real member photos.
- `images/vibes/`: twelve generated scene photographs for Vibes covers and matching game choices. Optimized local JPEGs; full prompts and mapping notes are in `docs/design/vibes-image-prompts.md`.
- `fonts/`: offline font files and their licenses.
- `source-images/`: original portrait collages and unused generated welcome artwork; not bundled.

Design references and generation prompts live under `docs/design/`.

Check existing images before creating new ones. Save new runtime images under the relevant `images/<feature>/` folder, register the exact paths in `pubspec.yaml`, and expose paths in `AppAssets`. Do not reference build output or generated images outside the project at runtime. Source images and design references should not be registered as Flutter assets.
