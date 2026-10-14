# Profile setup and discovery

This module exposes authenticated profile editing and discovery endpoints.

Discovery supports age, gender, distance, location, online, verified, and
interest filters. Interest filters accept either one `interest` query value or
up to eight `interests` (comma-separated or repeated query values); multiple
interests use “match any” behavior. Likes and passes are persisted separately.
Discover excludes profiles the current user has already liked or passed.

Discovery uses the member's saved GPS coordinates by default. If GPS is missing,
normal discovery asks the member to enable location. Travel mode supports
Bangalore/Bengaluru, Mumbai, Delhi, and Hyderabad using the selected city's approximate
center instead of the member's location. An explicit latitude/longitude pair
overrides either origin; unsupported travel cities require that pair.
When a center is available, every discovery mode enforces the radius and excludes
profiles without coordinates. City labels do not restrict a geographic search,
so a profile across a city boundary can still appear within the radius.
Saved profile city labels never replace device coordinates in normal discovery.
Nearby ranks by actual distance even when a member hides their distance; the
internal sorting distance is omitted from the response.

The pass endpoint is `POST /profile/discover/:userId/pass`. Its records are
stored in `ProfilePass` and cascade-delete with either account. Apply the
`add_profile_passes` Prisma migration before deploying the backend version that
uses this endpoint.
