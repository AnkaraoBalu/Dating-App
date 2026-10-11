# Development demo profiles

`demo-users.json` is the source fixture for 10 fictional male and 10 fictional
female profiles. The seed script creates complete onboarding and profile rows,
four portrait URLs, and three prompts per profile so they can appear in
discovery and profile screens. Photos use the public Pravatar demo image
service, so the device needs internet access to display them.

From the `backend` directory, run:

```sh
ALLOW_DEMO_SEED=true npm run backend:db:seed:demo
```

To sign in to one of these profiles from the debug app, configure `backend/.env`
and restart the API:

```env
DEMO_AUTH_ENABLED=true
DEMO_AUTH_SECRET=<at-least-32-random-characters>
```

Generate a local secret with `openssl rand -hex 32`. The app shows the demo
picker only in debug builds. Demo sessions expire after one hour; choose a
profile again to start a new session.

The script refuses production mode and requires the explicit flag. It upserts
only records whose Clerk IDs start with `demo_matchify_`; rerunning refreshes
those demo records and leaves other users untouched. Demo sign-in issues a
development-only session rather than creating Clerk identities. The seed does
not create likes, matches, or conversations.

## Removing demo sign-in later

The demo implementation lives in `src/modules/demo-auth`, `prisma/demo-auth`,
and `DatingAPP/lib/features/demo_auth`. The integration hooks are the
debug-only button in `DatingAPP/lib/features/login/presentation/screens/login_screen.dart`,
the demo-session branch in `DatingAPP/lib/app/dating_app.dart`, demo logout in
the profile settings screen, demo-token acceptance in the HTTP guard and chat
gateway, the seeded-user lookup in `UsersService`, and the two `DEMO_AUTH_*`
environment fields. Removing those hooks and the module import returns the
app to Clerk-only sign-in.
