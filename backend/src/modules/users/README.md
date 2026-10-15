# Onboarding lifestyle selections

The API accepts `vibeTypes` (up to 3), `idealFridays` (up to 3), and
`currentEras` (up to 2) as arrays of distinct allowed option IDs. An empty
array clears that answer; an omitted field leaves it unchanged. Null arrays,
duplicates, unknown options, and selections above the limit are rejected.

The migration `20261015090000_onboarding_multiple_choices` adds these columns
and copies each existing scalar answer into a one-element array. Legacy
`vibeType`, `idealFriday`, and `currentEra` columns remain available. New writes
mirror the first selection into the legacy column. A legacy scalar write
replaces its corresponding array; a legacy null clears it. If both forms are
provided, the array takes precedence, including an empty array.

Deploy in this order:

1. Apply migrations with `npm run backend:db:deploy` from `backend/`.
2. Generate Prisma Client and deploy the updated backend.
3. Release the updated Flutter app.

The migration is additive and retains old answers. The new app reads legacy
scalar responses as single selections when arrays are absent, but saving
multiple selections requires the updated backend. These lifestyle answers do
not change the discovery scoring formula in this update.
