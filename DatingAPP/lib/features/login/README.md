# Login and account setup

The login screen currently offers Google and email. Clerk handles Google OAuth and email one-time codes. Users can choose sign-in or account creation by email. Phone OTP screens remain in the project for later activation. Successful authentication returns to the app root, syncs the Clerk user with the Just2 API, and resumes account setup or opens Home according to the saved profile.

## Configuration

Copy `.env.example` to `.env` in the `DatingAPP/` directory, then set:

- `API_URL` — Just2 API base URL ending in `/api/v1`. For a physical phone, use the development computer's LAN address, not `localhost`.
- `CLERK_PUBLISHABLE_KEY` — Clerk's public publishable key. The Clerk secret key belongs only in `backend/.env`.

Flutter loads the local `.env` as a bundled asset. It contains public values only; do not put secrets in it.

Run `flutter run` from `DatingAPP/` after copying the example and adding your Clerk publishable key. For a physical Android phone, set `API_URL` to the computer's LAN IP and port 3000 (the current local `.env` points to `192.168.1.5`). Update this when the computer's IP changes. Android allows cleartext HTTP for debug builds only; production must use HTTPS.

The Flutter Clerk package is currently beta. Google OAuth uses the `matchify://auth/oauth` deep link configured in the Android and iOS app metadata.

Login screens keep authentication state and navigation in their screen files. Shared visual pieces live in `presentation/widgets/`, phone-country data lives in `data/phone_countries.dart`, and shared login text lives in `data/login_copy.dart`.

## Clerk dashboard setup

- Enable Google as a social connection for sign-up and sign-in.
- Enable email address sign-in/sign-up with email codes.
- Phone sign-in is intentionally not shown yet. When enabling it later, turn on phone sign-in/sign-up and SMS verification, then allow the countries to which you need to send SMS. Clerk's SMS allowlist may reject countries that are not enabled.
- Avoid requiring extra sign-up fields until the app collects them.

The backend verifies Clerk session tokens and syncs authenticated users at `GET /api/v1/users/me`. After location permission is allowed or deferred, Just2 collects a birthday (18+), gender identity, who the user is interested in, dating intentions, vibe, ideal Friday, up to five interests, up to five combined music genres and artists, current era, up to eight deal-breakers, and a preferred distance radius with a nearby-only option. All answers are saved in the user's `OnboardingProfile`. The onboarding API also supports saving location coordinates when provided.

## Real accounts and demo accounts

Real users select **Continue with Google** or **Continue with Email**. Google opens Clerk's OAuth flow; email sends a Clerk verification code. Both use Clerk's session JWT to call the backend. `UsersService.syncFromClerk` reads the authenticated Clerk identity and creates or updates its Just2 user without replacing the saved onboarding answers or app display name.

The debug-only **Continue with a demo user** button lives in `features/demo_auth/`. Its backend counterpart lives in `src/modules/demo-auth/`. Demo tokens require `DEMO_AUTH_ENABLED=true` and are rejected in production. Enabling demo login does not replace verification of real Clerk session tokens.

`data/clerk_operation.dart` captures Clerk's streamed errors for code sending, verification, resending and Google login. The app creates a new account gate when the Clerk user or session changes, so a previous user's profile cannot remain loaded. When no Clerk publishable key is configured, real login buttons are disabled and the login screen explains the configuration issue.

To check the flow on a physical device:

1. Choose Google or email on the login screen. Use **Create account** for a new identity and **Sign in** for an existing one.
2. Complete Google authentication or enter the emailed code. Confirm that account setup opens for a new user and the saved profile opens for a returning user.
3. Log out from Profile settings and log in with another real account. Confirm that its profile and messages appear.
4. Check invalid email codes and failed requests: the app should show the failure and stay on the login screen.

Automated checks use offline fixtures, not live Google accounts or emailed codes:

```sh
# From DatingAPP/
flutter test test/clerk_operation_test.dart test/login_flow_test.dart test/login_validators_test.dart

# From backend/
npm run backend:build
node --test test/clerk-auth.test.cjs
```
