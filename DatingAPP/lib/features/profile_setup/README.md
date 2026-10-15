# Profile setup

This feature follows the onboarding layout:

- `data/` holds screen copy and sample options.
- `models/` holds the in-memory draft state for the design preview.
- `presentation/screens/` owns navigation and the shared scaffold.
- `presentation/widgets/` holds the photo, prompt, details, and shared layouts.

The widget files are Dart parts of the screen library so they can share the
wizard's draft state. The profile setup API persists profile fields, photos, and
prompts, then marks the profile complete when the required setup is finished.

Prompts are optional (up to 5). Prompt setup has four visual steps: browse
categories, pick a question, answer it in a popup (a prompt is only added once
its answer is saved), review the answered prompts, and preview them on a
profile card. Draft answers are held in
memory while editing and saved through the profile setup API.
