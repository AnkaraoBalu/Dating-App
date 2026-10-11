CREATE TABLE "VibeRoomMember" (
    "roomId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" VARCHAR(24) NOT NULL DEFAULT 'Listener',
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),

    CONSTRAINT "VibeRoomMember_pkey" PRIMARY KEY ("roomId", "userId")
);

CREATE TABLE "VibeRoomMessage" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "clientMessageId" VARCHAR(80) NOT NULL,
    "text" VARCHAR(1000) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VibeRoomMessage_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "VibeRoomMember_userId_leftAt_joinedAt_idx"
ON "VibeRoomMember"("userId", "leftAt", "joinedAt");

CREATE UNIQUE INDEX "VibeRoomMessage_senderId_clientMessageId_key"
ON "VibeRoomMessage"("senderId", "clientMessageId");

CREATE INDEX "VibeRoomMessage_roomId_createdAt_id_idx"
ON "VibeRoomMessage"("roomId", "createdAt", "id");

ALTER TABLE "VibeRoomMember"
ADD CONSTRAINT "VibeRoomMember_roomId_fkey"
FOREIGN KEY ("roomId") REFERENCES "VibeRoom"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "VibeRoomMember"
ADD CONSTRAINT "VibeRoomMember_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "VibeRoomMessage"
ADD CONSTRAINT "VibeRoomMessage_roomId_fkey"
FOREIGN KEY ("roomId") REFERENCES "VibeRoom"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "VibeRoomMessage"
ADD CONSTRAINT "VibeRoomMessage_senderId_fkey"
FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

INSERT INTO "VibeRoomMember" ("roomId", "userId", "role", "joinedAt")
SELECT "id", "hostUserId", 'Host', "createdAt"
FROM "VibeRoom"
ON CONFLICT ("roomId", "userId") DO NOTHING;
