CREATE TABLE "ProfilePass" (
    "id" TEXT NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "toUserId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProfilePass_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ProfilePass_fromUserId_toUserId_key"
ON "ProfilePass"("fromUserId", "toUserId");

CREATE INDEX "ProfilePass_toUserId_createdAt_idx"
ON "ProfilePass"("toUserId", "createdAt");

ALTER TABLE "ProfilePass"
ADD CONSTRAINT "ProfilePass_fromUserId_fkey"
FOREIGN KEY ("fromUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ProfilePass"
ADD CONSTRAINT "ProfilePass_toUserId_fkey"
FOREIGN KEY ("toUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
