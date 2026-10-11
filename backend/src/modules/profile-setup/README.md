# Profile setup and discovery

This module exposes authenticated profile editing and discovery endpoints.

Discovery supports age, gender, distance, location, online, verified, and
interest filters. Interest filters accept either one `interest` query value or
up to eight `interests` (comma-separated or repeated query values); multiple
interests use “match any” behavior. Likes and passes are persisted separately.
Discover excludes profiles the current user has already liked or passed.

The pass endpoint is `POST /profile/discover/:userId/pass`. Its records are
stored in `ProfilePass` and cascade-delete with either account. Apply the
`add_profile_passes` Prisma migration before deploying the backend version that
uses this endpoint.
