# Just2 website architecture

## Purpose and scope

`frontend/` is the public React website introducing the Just2 mobile app.
The initial site explains discovery, Vibes, mutual matches, and conversations.
It is independent of the Flutter client and NestJS server, and currently uses
local presentation content without authentication or backend requests.

The website includes nine public pages and a not-found page, shared navigation,
interactive illustrative demos, and responsive motion. Store URLs and approved
privacy/terms documents are still required before public launch. Those routes
explicitly describe their availability rather than presenting invented content.
Do not advertise parked app actions as available; check ../SCREENS.md before
adding product claims.

## Stack

- React + strict TypeScript for components and typed content.
- Vite for development and static production builds.
- React Router for page routes and shared layout.
- styled-components for separate, typed `*.styles.ts` files.
- Yarn Classic 1.22.22 with a committed lockfile.
- Just2's Flutter forest, coral, and cream palette in one theme.

## Source structure

```text
frontend/
├── ARCHITECTURE.md
├── README.md
├── package.json / yarn.lock
├── index.html / vite.config.ts / tsconfig.json
├── public/                         served unchanged
├── src/
│   ├── main.tsx                    React mount
│   ├── api/                        HTTP transport and parsing (reserved)
│   ├── api-hooks/                  remote-data hooks (reserved)
│   ├── app/
│   │   ├── app.tsx                 router entry
│   │   ├── home/
│   │   │   ├── HomePage.tsx
│   │   │   ├── HomePage.styles.ts
│   │   │   ├── index.ts
│   │   │   ├── components/
│   │   │   │   └── home-hero/
│   │   │   │       ├── HomeHero.tsx
│   │   │   │       ├── HomeHero.styles.ts
│   │   │   │       └── index.ts
│   │   │   ├── hooks/
│   │   │   └── utils/
│   │   ├── about/, how-it-works/, vibes/, help/, download/
│   │   ├── community-guidelines/, privacy/, terms/
│   │   └── not-found/
│   │       ├── NotFoundPage.tsx
│   │       ├── NotFoundPage.styles.ts
│   │       └── index.ts
│   ├── assets/                     imported images, fonts, icons
│   ├── components/                 shared UI only
│   │   ├── common-container/
│   │   ├── navbar/
│   │   ├── footer/
│   │   ├── reveal/, story-journey/, match-demo/, chat-demo/
│   │   ├── page-hero/, app-cta/, document-notice/, ui/
│   │   └── index.ts
│   ├── constants/navigation.ts
│   ├── context/                    shared state when needed
│   ├── hooks/                      reusable UI hooks
│   ├── layouts/website-layout/
│   ├── providers/                  theme and browser router
│   ├── router/                     route declarations
│   ├── styles/                     theme, global styles, theme typing
│   ├── types/                      shared domain types
│   └── utils/                      shared pure helpers
├── node_modules/                   generated, ignored
└── dist/                           generated production output, ignored
```

Reserved directories contain explanatory README files rather than unused
implementations. `out-tsc/` is ignored for possible future generated output;
the current TypeScript check uses `noEmit`, and Vite produces `dist/`.

## Component convention

Every reusable component has its own kebab-case folder with a PascalCase
`.tsx` file, a matching `.styles.ts` file, and an explicit `index.ts` export.
Rendering and event handling live in `.tsx`; layout, colors, media queries,
and visual variants live in `.styles.ts`. Avoid inline styles and styles
inside component render functions. Use `$`-prefixed transient styling props.
Keep component props local unless genuinely shared by several features.

A page owns route composition. Put page-only sections in that feature's
`components/`; promote a component to top-level `components/` only when it
is shared or part of the website shell. Feature data, hooks, and helpers stay
inside the feature. Small components can remain in one file; split substantial
sections by responsibility and aim for source files below 300 lines.

## Composition and dependency direction

```text
main.tsx
  → AppProviders (theme, global styles, BrowserRouter)
    → App → AppRouter
      → WebsiteLayout (RouteEffects + Navbar → Outlet → Footer)
        → Page → feature sections + shared components
```

Pages may import shared components and feature-local modules. Shared components
must not import pages. The router imports page entry exports. Providers own
cross-cutting infrastructure; do not add providers for local UI state. API
clients should never import presentation components; API hooks delegate to
clients and expose typed loading/error/data state when remote content exists.
Use explicit exports; do not create a single barrel importing the whole app.

## Routes and navigation

| URL | Page / destination |
| --- | --- |
| `/` | Home: introduction, scroll story, matching and chat demos |
| `/about` | Our story and values |
| `/how-it-works` | Discovery, Vibes, matches, and chat walkthrough |
| `/vibes` | Filterable illustrative interest themes |
| `/help` | Searchable, categorized FAQ accordions |
| `/help#chat` | Opens the chat FAQ |
| `/download` | App introduction, demo, and store-link availability |
| `/community-guidelines` | Community principles |
| `/privacy` | Privacy document availability notice |
| `/terms` | Terms document availability notice |
| `*` | Not-found page with a home link |

RouteEffects sets page titles, resets scroll, focuses main content on page
changes, and handles section hashes. The mobile navigation uses a native modal
`dialog`, locks background scrolling, closes on navigation/Escape, and returns
focus on dismissal. The shell includes a skip link and visible keyboard focus.

## Motion and interaction

- Home sections use viewport-height scenes on desktop and native proximity scroll
  snapping, scoped to Home and removed on route changes. `ScrollMore` links
  smoothly advance to the next section, or the next sticky walkthrough step.
  Mobile, short viewports, and reduced-motion settings use ordinary scrolling.
  Links retain native hash destinations and move keyboard focus to each section.
- `Reveal` uses IntersectionObserver for one-time section entrances.
- `StoryJourney` uses native sticky positioning over three viewport heights;
  requestAnimationFrame updates the active step from scroll position. Progress
  buttons also navigate the steps. There is no wheel interception.
- On widths up to 850px, heights up to 700px, or reduced-motion preference,
  the walkthrough shows all three steps as ordinary stacked content.
- Global styles provide smooth anchor scrolling, floating accents, and the
  interest ticker. Reduced-motion styles disable animations and smooth scroll.
- MatchDemo and ChatDemo own local illustrative state only. Save/unsave and
  leave/return demonstrate chat behavior without creating messages or accounts.
- Vibes filters and FAQ search use typed local data. FAQs use native details.

## Content, assets, and integrations

Keep repeated presentation content typed under the feature's `data/` folder.
Do not invent user counts, testimonials, store availability, or certifications.
Use real app screenshots when approved assets become available. The hero and demos are illustrative compositions, not app screenshots.
`public/images/` reuses six existing generated Flutter portraits.
`public/fonts/` contains Manrope, DM Serif Display, and Caveat copied from the
Flutter assets with their OFL licenses; no external font requests are needed.

Use `src/assets/` for assets imported by TypeScript and processed by Vite;
use `public/` for files that require a stable unchanged URL. Never put secrets
or private credentials in either directory. If public API access is added,
read only explicitly public Vite variables (`VITE_*`); they are shipped to the
browser. Never copy backend/.env, Firebase server keys, or database credentials.

## Development, build, and hosting

From `frontend/`, run `yarn install`, then `yarn ui:dev`. Vite serves
http://127.0.0.1:5173 with a strict port so a conflict is reported explicitly.
`yarn ui:typecheck` checks strict types; `yarn ui:build` checks types and builds
static files into `dist/`; `yarn ui:preview` serves the production build.
The production host must rewrite unknown page paths to `index.html` for
BrowserRouter. Choose hosting and add deployment configuration later.

This task prepares a local website; it does not publish a hosted site.


## Design reference and validation

The site's editorial sections, sticky scroll storytelling, and mobile navigation
were inspired by Rivet and adapted to Just2's own content and palette. It uses
native browser motion without additional animation dependencies.

Browser validation covered all ten route outcomes at 1440px, 390px, and 320px,
with no horizontal overflow, missing images, or runtime exceptions. Interaction
checks covered matching/reset, chat save/unsave/leave, scroll steps, Vibes filters,
FAQ search/clear/expand/deep links, mobile navigation, and reduced motion.
TypeScript and the production build also passed.
