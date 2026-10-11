CREATE TABLE "OnboardingProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "birthDate" DATE,
    "genderIdentity" TEXT,
    "interestedIn" TEXT,
    "datingIntentions" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "locationPermissionGranted" BOOLEAN NOT NULL DEFAULT false,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OnboardingProfile_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "OnboardingProfile_userId_key" ON "OnboardingProfile"("userId");
CREATE INDEX "OnboardingProfile_completedAt_idx" ON "OnboardingProfile"("completedAt");

ALTER TABLE "OnboardingProfile"
ADD CONSTRAINT "OnboardingProfile_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
