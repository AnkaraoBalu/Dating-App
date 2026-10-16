# Safety: block, unmatch and report

All routes need a signed-in member and take the other member's user id.

| Route | Effect |
| --- | --- |
| `POST /safety/users/:userId/block` | Saves a `ProfileBlock`, removes likes in both directions and the pair's conversation (messages and calls). |
| `POST /safety/users/:userId/unmatch` | Removes likes and the conversation, and records a pass in both directions so neither is shown the other again. No block is saved. |
| `POST /safety/users/:userId/report` | Body `{ reason, details?, source? }`. Saves a `ProfileReport`, blocks the member for the reporter and emails the team inbox. |

A block in either direction excludes the pair from discovery and rejects new
likes (`Profile not found.`). After each action both members receive
`inbox:changed`, so open apps reload their matches and chats.

Report reasons: `fake_profile`, `inappropriate_photos`, `harassment`,
`offensive_messages`, `scam_or_spam`, `underage`, `other`. Sources: `profile`,
`discover`, `chat`, `match`.

Report emails use the SMTP settings (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`,
`SMTP_PASS`) and go to `REPORTS_EMAIL_TO`, or `SMTP_USER` when unset. Without
SMTP the report is still saved and a warning is logged. Review open reports in
the `ProfileReport` table (`status = 'open'`).

Apply migration `20261016120000_profile_blocks_and_reports` before deploying.
