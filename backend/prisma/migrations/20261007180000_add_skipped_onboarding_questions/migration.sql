ALTER TABLE "OnboardingProfile"
ADD COLUMN "skippedQuestions" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
