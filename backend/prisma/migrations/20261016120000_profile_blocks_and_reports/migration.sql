-- Block and report, required for member safety.
CREATE TABLE "ProfileBlock" (
    "id" TEXT NOT NULL,
    "blockerId" TEXT NOT NULL,
    "blockedId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ProfileBlock_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "ProfileBlock_blockerId_blockedId_key" ON "ProfileBlock"("blockerId", "blockedId");
CREATE INDEX "ProfileBlock_blockedId_idx" ON "ProfileBlock"("blockedId");
ALTER TABLE "ProfileBlock" ADD CONSTRAINT "ProfileBlock_blockerId_fkey" FOREIGN KEY ("blockerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProfileBlock" ADD CONSTRAINT "ProfileBlock_blockedId_fkey" FOREIGN KEY ("blockedId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "ProfileReport" (
    "id" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "reportedUserId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "details" TEXT,
    "source" TEXT NOT NULL DEFAULT 'profile',
    "status" TEXT NOT NULL DEFAULT 'open',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ProfileReport_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ProfileReport_reportedUserId_createdAt_idx" ON "ProfileReport"("reportedUserId", "createdAt");
CREATE INDEX "ProfileReport_status_createdAt_idx" ON "ProfileReport"("status", "createdAt");
ALTER TABLE "ProfileReport" ADD CONSTRAINT "ProfileReport_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProfileReport" ADD CONSTRAINT "ProfileReport_reportedUserId_fkey" FOREIGN KEY ("reportedUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
