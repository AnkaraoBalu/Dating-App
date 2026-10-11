# Profile setup

This feature follows the onboarding layout:

- `data/` holds screen copy and sample options.
- `models/` holds the in-memory draft state for the design preview.
- `presentation/screens/` owns navigation and the shared scaffold.
- `presentation/widgets/` holds the photo, prompt, details, and shared layouts.

The widget files are Dart parts of the screen library so they can share the
wizard's draft state. The profile setup API persists profile fields, photos, and
prompts, then marks the profile complete when the required setup is finished.

Prompt setup has four visual steps: browse categories, pick 3–5 questions,
answer each one, and preview them on a profile card. Draft answers are held in
memory while editing and saved through the profile setup API.
