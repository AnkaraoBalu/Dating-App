# Matchify backend

NestJS API service written in TypeScript. It is independently installed and deployed from the Flutter app.

## Requirements

- Node.js 22 or newer
- Yarn 1 (Classic) or a modern Yarn release

## Install and run locally

```sh
cp .env.example .env
yarn install
yarn backend:dev
```

The API listens on `http://localhost:3000`. The health endpoint is `GET /api/v1/health`. After Clerk sign-in, send the Clerk session token as `Authorization: Bearer <token>` to `GET /api/v1/users/me` to create or refresh the local user record. The authenticated onboarding endpoints update and complete the user's onboarding profile.

## Scripts

- `yarn install` — install dependencies
- `yarn backend:dev` — start Nest in watch mode
- `yarn backend:build` — compile the application to `dist/`
- `yarn backend:start` — start the compiled application
- `yarn backend:typecheck` — check TypeScript types
- `yarn backend:format` — format TypeScript source and test files
- `yarn backend:db:generate` — generate Prisma Client after schema changes
- `yarn backend:db:migrate --name <migration_name>` — create and apply a development migration
- `yarn backend:db:deploy` — apply committed migrations in production

## Environment and database access

Environment values are validated in `src/config/env.validation.ts`. Put local values in `.env`, which is ignored by Git. In production, configure variables in the hosting provider's secret manager. Never commit database URLs, passwords, API keys, or production `.env` files.

Set `DB_URL` to your PostgreSQL connection string and `CLERK_SECRET_KEY` to the Clerk secret key. Keep both values only in backend `.env` locally or the hosting provider's secret store. Never bundle the Clerk secret or database URL in the Flutter app. Users sign in through Clerk; the API verifies Clerk bearer tokens and stores a local user profile keyed by Clerk's user ID.

## Structure

```text
src/
  config/                 # Environment validation and app configuration
  database/               # Prisma service and database module
  modules/
    health/               # Health check endpoint
    users/                # Clerk user sync and onboarding profile
  app.module.ts           # Root Nest module
  main.ts                 # Application bootstrap
```

Add future domains as separate modules under `src/modules/` (for example `auth`, `profiles`, `matches`, and `messages`). Keep controllers focused on HTTP and move business rules and persistence into services and repositories as features are defined.

All onboarding answers are stored together in the one-to-one `OnboardingProfile` table. This includes identity and dating preferences, energy, ideal Friday, up to five interests, up to five combined music genres and artists, current era, up to eight deal-breakers, and preferred distance (5, 10, 25, 50, or 100 km) with a nearby-only toggle. Update answers with `PATCH /api/v1/users/me/onboarding`; complete onboarding with `POST /api/v1/users/me/onboarding/complete`.

## Deployment

Deploy this API as a Node.js service or container, independently from the Flutter builds. Set `NODE_ENV=production`, the port expected by the host, and database secrets in the host's secret settings. Serve it over HTTPS and restrict database network access to the API service.
