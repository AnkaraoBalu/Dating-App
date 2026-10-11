CREATE TABLE "UserPreference" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "interestedIn" TEXT,
    "datingIntentions" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserPreference_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "UserPreference_userId_key" ON "UserPreference"("userId");

INSERT INTO "UserPreference" ("id", "userId", "interestedIn", "datingIntentions", "createdAt", "updatedAt")
SELECT 'pref_' || "id", "userId", "interestedIn", "datingIntentions", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM "OnboardingProfile"
WHERE "interestedIn" IS NOT NULL OR cardinality("datingIntentions") > 0;

ALTER TABLE "UserPreference"
ADD CONSTRAINT "UserPreference_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "OnboardingProfile"
DROP COLUMN "interestedIn",
DROP COLUMN "datingIntentions";
