# Matchify website

React + TypeScript public website for introducing the mobile app. Read
[ARCHITECTURE.md](ARCHITECTURE.md) for folder rules, routes, and future scope.

Use Node.js 22.12+ and Yarn Classic 1.22.22.

```sh
cd frontend
yarn install
yarn ui:dev
```

Open http://127.0.0.1:5173. Stop the server with Ctrl+C.

```sh
yarn ui:typecheck
yarn ui:build
yarn ui:preview
```

Components use `Component.tsx`, `Component.styles.ts`, and `index.ts` in their
own folders. Shared components live in `src/components/`; page-only components
live in `src/app/<feature>/components/`. No backend or credentials are needed.
Production output is `dist/`; deployment is not configured yet.

The website includes Home, Our story, How it works, Vibes, Help, Meet the app,
Community, Privacy, Terms, and a not-found page. Features include a responsive
modal menu, scroll storytelling, reduced-motion support, searchable FAQs,
Vibes filters, and interactive matching/chat demos.

Store links and approved privacy/terms documents are pending. The demos use
local state and do not connect to real accounts. Production hosting must serve
`index.html` for page routes so direct links work with BrowserRouter.

## Deploying

**Cloudflare Pages** (recommended) builds straight from git, no Docker needed:
root directory `frontend`, build command `yarn ui:build`, output directory
`dist`, environment variable `NODE_VERSION=22`. Pages serves `index.html` for
unknown paths, so routes like `/about` work on refresh.

**Container hosts:** `frontend/Dockerfile` builds the site and serves it with
nginx on port 8080 (`nginx.conf` handles client-side routes and asset caching).

```sh
docker build -t matchify-frontend ./frontend
docker run -p 8080:8080 matchify-frontend
```
