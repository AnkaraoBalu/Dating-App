# Messages module

This module provides persisted text, one-time location, and image messages
between users who have a mutual profile like. REST uploads images and loads
history; Socket.IO delivers text/location events and notifies conversation
members about persisted image messages.

## Files

- `messages.controller.ts` exposes the authenticated REST endpoints.
- `messages.service.ts` checks matches and conversation membership, then writes
  messages to PostgreSQL.
- `conversations.service.ts` builds the conversation list with peer profiles,
  latest message previews, and unread counts.
- `messages.gateway.ts` authenticates the Socket.IO connection with a Clerk
  token and relays message events to the conversation room.
- `message-media.service.ts` validates and stores chat images in Cloudinary,
  then persists the message before returning it.
- `messages.module.ts` registers the controller, service, and gateway.
- `prisma/schema.prisma` defines `Conversation` and `Message`.
- `prisma/migrations/20261009120000_add_messages/migration.sql` creates their
  tables and indexes.

## REST endpoints

- `POST /api/v1/messages/conversations/:otherUserId` creates or returns the
  conversation for a mutual match.
- `GET /api/v1/messages/conversations` returns actual conversations, each
  participant's unread count, peer profile, and latest message preview. Add
  `?search=` to search peer names and latest message previews.
- `POST /api/v1/messages/conversations/:conversationId/read` clears the
  authenticated participant's unread count.
- `GET /api/v1/messages/conversations/:conversationId/messages?limit=50` returns
  the latest messages in time order (maximum 100 per page).
- `POST /api/v1/messages/conversations/:conversationId/images` accepts one
  JPEG, PNG, or WebP multipart image plus `clientMessageId` and optional
  `caption`. It stores the file, persists the message, broadcasts `message:new`,
  and returns the saved message.
- Pass the response `nextCursor` as `before` to load the next older page. The
  cursor is scoped to the requested conversation and ordered by creation time
  plus message ID so pages remain stable when timestamps tie.

All endpoints require `Authorization: Bearer <Clerk session token>`.

## Socket.IO events

The Flutter client connects with the Clerk token in Socket.IO's `auth.token`.
The server validates the token and sends `chat:ready` only after it maps the
Clerk user to an app user.

`chat:ready.userId` and history `viewerId` are database user IDs. Both live
events and saved history compare `senderId` with that identity: own messages
appear on the right and peer messages on the left. Each Flutter chat uses a
fresh Socket.IO manager (`forceNew`, no multiplexing), so switching accounts
cannot reuse another account's authenticated socket. The auth callback fetches
a fresh token on every reconnect.

- Client → server: `conversation:join` with `{ conversationId }`.
- Server → client: `conversation:joined` after checking membership.
- Client → server: `message:send` with text or location payloads.
- Server → room: `message:new` after saving the message.
- Server → sender: `message:sent` or `message:error`.

The successful send acknowledgement includes the canonical saved message,
so delivery confirmation does not depend on the sender receiving a room echo.
History loads in parallel with authentication and room joining. After every
join the client refreshes history to fill the initial loading gap; reconnect
recovery follows older pages until it reaches the last known saved message.
Read receipts apply only when the peer read the message, and persisted read
resets serialize with unread increments to avoid losing a concurrent badge.

Regression checks: `npm run backend:test` and, from `DatingAPP`,
`flutter test --no-pub test/chat_messaging_test.dart`. The Flutter checks use
a local Socket.IO fixture in `backend/test/fixtures` without modifying the app
database or requiring Clerk credentials.

Messages are saved before broadcasting. `clientMessageId` makes retries
idempotent. On reconnect, the client rejoins the room and reloads recent
history, because a socket connection itself is not message storage. The client
marks unacknowledged messages as failed after a timeout and retries them with
the same ID when the user taps retry.

## Apply the database migration

From the `backend` directory, run `npx prisma migrate deploy` against the
configured database, then restart the backend. This applies pending migrations,
including per-participant conversation unread counters.
