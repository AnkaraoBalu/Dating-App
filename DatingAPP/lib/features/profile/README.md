# Profile management

The Home screen owns one `ProfileController`. The Profile tab and its routes share
that controller so saved edits, photo order, and privacy controls refresh together.
This feature covers the signed-in user's own profile (the Profile tab); other
people's profiles shown during discovery live in `home/`. Screens are in
`presentation/screens`; reusable controls, the options sheet, and the editor
sheets used by `ProfileEditScreen` (`profile_edit_*` part files) are in
`presentation/widgets`. `MemberProfile` reads the authenticated profile response,
including the existing onboarding answers under `user.onboardingProfile`.

Profile editing uses one scrollable page with a separate edit action for each
section. Each section opens an editor sheet and saves independently, so users can
change one detail without stepping through the rest of the profile. Photo
management stays in the gallery, which supports six photos, changing the main
photo, removing photos, and editing crops, rotation, brightness, and
black-and-white treatment. The photo editor uploads a PNG to replace the owned
photo in its existing slot.

Backend additions:

- `PATCH /users/me/name` saves the chosen name in `User.username`, independently of Clerk names.
- `GET /profile` includes the user's onboarding information.
- `PUT /profile/photos/:id` replaces an owned photo.
- `GET /profile/insights` returns likes received, likes sent, and mutual matches.
- `PATCH /profile` saves industry, smoking, drinking, diet, religion, and the
  `showProfile`, `showDistance`, and `showOnlineStatus` controls.

Apply the committed `20261008150000_add_profile_management` migration before
running this backend version (`npm run backend:db:deploy` from `backend`), and
generate Prisma Client (`npm run backend:db:generate`). Deploy migrations only to
the database intended for that environment.

Privacy controls affect discovery queries and response fields. Paused profiles
are excluded from discovery; hidden distance also suppresses approximate map
coordinates; hidden online status excludes the profile from Online results.

Verification and Instagram services, account deletion, blocking/reporting,
notifications/preferences integrations, and paid visibility products are not
implemented. The UI does not invent verification status, engagement counts,
conversion rates, or a public share URL. The options sheet can copy the member's
profile summary. Completeness is a checklist of actual saved profile fields.

Checks: `npm run backend:test` and
`flutter test --no-pub test/profile_management_test.dart`.
