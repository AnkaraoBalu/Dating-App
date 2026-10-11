ALTER TABLE "User" ADD COLUMN "lastActiveAt" TIMESTAMP(3);

ALTER TABLE "OnboardingProfile"
ADD COLUMN "latitude" DOUBLE PRECISION,
ADD COLUMN "longitude" DOUBLE PRECISION;

CREATE TABLE "ProfileLike" (
    "id" TEXT NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "toUserId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ProfileLike_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ProfileLike_fromUserId_toUserId_key"
ON "ProfileLike"("fromUserId", "toUserId");
CREATE INDEX "ProfileLike_toUserId_createdAt_idx"
ON "ProfileLike"("toUserId", "createdAt");

ALTER TABLE "ProfileLike"
ADD CONSTRAINT "ProfileLike_fromUserId_fkey"
FOREIGN KEY ("fromUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ProfileLike"
ADD CONSTRAINT "ProfileLike_toUserId_fkey"
FOREIGN KEY ("toUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
