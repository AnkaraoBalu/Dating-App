-- Preserve legacy columns for older app versions.
ALTER TABLE "OnboardingProfile" ADD COLUMN "vibeTypes" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
UPDATE "OnboardingProfile" SET "vibeTypes" = ARRAY["vibeType"] WHERE "vibeType" IS NOT NULL;
ALTER TABLE "OnboardingProfile" ADD COLUMN "idealFridays" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
UPDATE "OnboardingProfile" SET "idealFridays" = ARRAY["idealFriday"] WHERE "idealFriday" IS NOT NULL;
ALTER TABLE "OnboardingProfile" ADD COLUMN "currentEras" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
UPDATE "OnboardingProfile" SET "currentEras" = ARRAY["currentEra"] WHERE "currentEra" IS NOT NULL;
