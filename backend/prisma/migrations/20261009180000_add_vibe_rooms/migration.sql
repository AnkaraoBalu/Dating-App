CREATE TABLE "VibeRoom" (
    "id" TEXT NOT NULL,
    "title" VARCHAR(40) NOT NULL,
    "description" TEXT NOT NULL,
    "categoryId" VARCHAR(80) NOT NULL,
    "emoji" VARCHAR(16) NOT NULL,
    "coverAsset" VARCHAR(255) NOT NULL,
    "hostUserId" TEXT NOT NULL,
    "participantCount" INTEGER NOT NULL DEFAULT 1,
    "city" VARCHAR(120) NOT NULL DEFAULT 'Hyderabad',
    "isLive" BOOLEAN NOT NULL DEFAULT false,
    "inviteOnly" BOOLEAN NOT NULL DEFAULT false,
    "maxParticipants" INTEGER NOT NULL DEFAULT 50,
    "scheduledFor" VARCHAR(120),
    "tags" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VibeRoom_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "VibeRoomSave" (
    "roomId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VibeRoomSave_pkey" PRIMARY KEY ("roomId", "userId")
);

CREATE INDEX "VibeRoom_categoryId_isLive_participantCount_idx"
ON "VibeRoom"("categoryId", "isLive", "participantCount");

CREATE INDEX "VibeRoom_hostUserId_createdAt_idx"
ON "VibeRoom"("hostUserId", "createdAt");

CREATE INDEX "VibeRoomSave_userId_createdAt_idx"
ON "VibeRoomSave"("userId", "createdAt");

ALTER TABLE "VibeRoom"
ADD CONSTRAINT "VibeRoom_hostUserId_fkey"
FOREIGN KEY ("hostUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "VibeRoomSave"
ADD CONSTRAINT "VibeRoomSave_roomId_fkey"
FOREIGN KEY ("roomId") REFERENCES "VibeRoom"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "VibeRoomSave"
ADD CONSTRAINT "VibeRoomSave_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
