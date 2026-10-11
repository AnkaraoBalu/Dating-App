# Matchify Clerk auth patch

This is the `clerk_auth` 0.0.18-beta package used by `clerk_flutter`, copied
locally under its MIT license. `DatingAPP/pubspec.yaml` selects it with a path
override so Flutter uses the same fix on every machine.

The upstream `ssoSignUp` flow passes a redirect URL to `attemptSignUp`, but
`createSignUp` omitted it from the request. Clerk then rejected Google sign-up
with `redirect_url is required when strategy is present`. This copy forwards
the redirect URL when creating and preparing a sign-up. Remove the override
when a published SDK version contains the fix.
