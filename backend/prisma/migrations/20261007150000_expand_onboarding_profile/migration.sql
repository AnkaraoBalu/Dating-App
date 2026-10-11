ALTER TABLE "OnboardingProfile"
ADD COLUMN "interestedIn" TEXT,
ADD COLUMN "datingIntentions" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "vibeType" TEXT,
ADD COLUMN "idealFriday" TEXT,
ADD COLUMN "interests" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "musicGenres" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "currentEra" TEXT,
ADD COLUMN "dealbreakers" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

UPDATE "OnboardingProfile" AS profile
SET
    "interestedIn" = preferences."interestedIn",
    "datingIntentions" = preferences."datingIntentions"
FROM "UserPreference" AS preferences
WHERE profile."userId" = preferences."userId";

DROP TABLE "UserPreference";
