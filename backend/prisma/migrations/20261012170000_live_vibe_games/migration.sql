CREATE TABLE "VibeGameSession" (
    "id" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "activeRoomId" TEXT,
    "hostUserId" TEXT NOT NULL,
    "gameType" VARCHAR(40) NOT NULL,
    "status" VARCHAR(16) NOT NULL DEFAULT 'waiting',
    "questionIndex" INTEGER NOT NULL DEFAULT 0,
    "maxPlayers" INTEGER NOT NULL DEFAULT 8,
    "startedAt" TIMESTAMP(3),
    "finishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "VibeGameSession_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "VibeGameParticipant" (
    "sessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),
    CONSTRAINT "VibeGameParticipant_pkey" PRIMARY KEY ("sessionId", "userId")
);

CREATE TABLE "VibeGameAnswer" (
    "sessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "questionIndex" INTEGER NOT NULL,
    "choiceIndex" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "VibeGameAnswer_pkey" PRIMARY KEY ("sessionId", "userId", "questionIndex")
);

CREATE UNIQUE INDEX "VibeGameSession_activeRoomId_key" ON "VibeGameSession"("activeRoomId");
CREATE INDEX "VibeGameSession_roomId_status_createdAt_idx" ON "VibeGameSession"("roomId", "status", "createdAt");
CREATE INDEX "VibeGameParticipant_userId_leftAt_joinedAt_idx" ON "VibeGameParticipant"("userId", "leftAt", "joinedAt");
CREATE INDEX "VibeGameAnswer_sessionId_questionIndex_idx" ON "VibeGameAnswer"("sessionId", "questionIndex");

ALTER TABLE "VibeGameSession" ADD CONSTRAINT "VibeGameSession_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "VibeRoom"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "VibeGameSession" ADD CONSTRAINT "VibeGameSession_hostUserId_fkey" FOREIGN KEY ("hostUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "VibeGameParticipant" ADD CONSTRAINT "VibeGameParticipant_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "VibeGameSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "VibeGameParticipant" ADD CONSTRAINT "VibeGameParticipant_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "VibeGameAnswer" ADD CONSTRAINT "VibeGameAnswer_sessionId_userId_fkey" FOREIGN KEY ("sessionId", "userId") REFERENCES "VibeGameParticipant"("sessionId", "userId") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "VibeGameSession" ADD COLUMN "questionDeadline" TIMESTAMP(3);
ALTER TABLE "VibeGameSession" ADD COLUMN "setup" JSONB;
