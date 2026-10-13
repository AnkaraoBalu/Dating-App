# Notifications module

Every push notification goes through this module.

## Files

- `notifications.service.ts`: registers phones and builds each notification
  (`newMessage`, `newMatch`, `newLike`, `vibeRoomJoined`, `vibeRoomMessage`, `incomingCall`).
- `firebase-push.sender.ts`: sends with Firebase Cloud Messaging and reports
  tokens Firebase rejects for good, which the service then deletes.
- `notifications.controller.ts`: `POST /notifications/devices` registers a phone
  (`{ token, platform: "android" | "ios" }`); `DELETE /notifications/devices`
  (`{ token }`) removes it on log out.
- `PushDevice` in `prisma/schema.prisma`: one row per phone. A token belongs to
  whoever signed in on that phone most recently.

## When pushes are sent

| Event                                    | Who gets it                                                                 | Text                                            | Tap opens         |
| ---------------------------------------- | --------------------------------------------------------------------------- | ----------------------------------------------- | ----------------- |
| New chat message (text, location, photo) | The recipient, unless they are looking at that chat right now               | Sender's name + preview                         | That conversation |
| Vibe room message                      | Active room members other than the sender who are not viewing the room live | Room title + sender's name and message preview | That Vibe room    |
| New Vibe room member                    | The room host, unless they are the one joining                              | Member's name joined the room                   | That Vibe room    |
| New mutual like                          | The member who didn't just like (the liker sees the celebration in the app) | "It's a match! 🎉"                              | Matches tab       |
| New one-sided like                       | The liked member                                                            | "Someone likes you 💘" (doesn't name the liker) | Likes received    |

Repeating a like doesn't push again. "Looking at that chat" comes from the
chat socket: the app reports `conversation:presence { active: false }` when an
open chat goes to the background. Vibe room members viewing the room receive
messages over the live room socket instead of a duplicate push. Sending is best
effort and never fails the request that caused it.

## Configuration

Set `FIREBASE_SERVICE_ACCOUNT_PATH` in `backend/.env` to the Firebase service
account key (Firebase console → Project settings → Service accounts →
Generate new private key). Keep the file outside the repository. Without it the
API runs normally and logs once that pushes are off.

The Flutter side is `DatingAPP/lib/features/notifications/`.
