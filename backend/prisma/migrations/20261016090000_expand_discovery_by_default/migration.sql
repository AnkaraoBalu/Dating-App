-- Discovery now shows people beyond the member's distance after nearby people,
-- unless the member opts into "only show people nearby". The old default (true)
-- was never enforced, so reset everyone to the new default.
ALTER TABLE "OnboardingProfile" ALTER COLUMN "onlyShowPeopleNearby" SET DEFAULT false;
UPDATE "OnboardingProfile" SET "onlyShowPeopleNearby" = false;
