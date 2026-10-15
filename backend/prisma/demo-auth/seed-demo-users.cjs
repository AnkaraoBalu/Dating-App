const fs = require("node:fs");
const path = require("node:path");

if (fs.existsSync(path.resolve(__dirname, "../../.env"))) {
  process.loadEnvFile(path.resolve(__dirname, "../../.env"));
}

const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");

const PREFIX = "demo_matchify_";
const PHOTO_PREFIX = "demo-matchify-";

function requiredEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required.`);
  return value;
}

function slug(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_|_$/g, "");
}

async function main() {
  if (process.env.NODE_ENV === "production") {
    throw new Error("Demo seeding is disabled when NODE_ENV=production.");
  }
  if (process.env.ALLOW_DEMO_SEED !== "true") {
    throw new Error(
      "Set ALLOW_DEMO_SEED=true explicitly to write demo profiles to this database.",
    );
  }

  const fixture = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, "demo-users.json"), "utf8"),
  );
  const personas = [
    ...fixture.boys.map((persona) => ({
      ...persona,
      gender: "man",
      interestedIn: "women",
    })),
    ...fixture.girls.map((persona) => ({
      ...persona,
      gender: "woman",
      interestedIn: "men",
    })),
  ];
  if (
    fixture.version !== 1 ||
    fixture.boys.length !== 10 ||
    fixture.girls.length !== 10
  ) {
    throw new Error(
      "Expected version 1 fixture with exactly 10 boys and 10 girls.",
    );
  }

  const adapter = new PrismaPg({
    connectionString: requiredEnvironment("DB_URL"),
  });
  const prisma = new PrismaClient({ adapter });
  const completedAt = new Date();

  try {
    for (const [index, persona] of personas.entries()) {
      const idSuffix = slug(persona.username);
      const clerkUserId = `${PREFIX}${idSuffix}`;
      const email = `${idSuffix}@demo.matchify.invalid`;
      const user = await prisma.user.upsert({
        where: { clerkUserId },
        create: {
          clerkUserId,
          email,
          username: persona.username,
          firstName: persona.username,
          lastName: "Demo",
          imageUrl: `https://i.pravatar.cc/900?img=${persona.image}`,
          lastActiveAt: completedAt,
        },
        update: {
          email,
          username: persona.username,
          firstName: persona.username,
          lastName: "Demo",
          imageUrl: `https://i.pravatar.cc/900?img=${persona.image}`,
          lastActiveAt: completedAt,
        },
      });

      const birthDate = new Date(
        Date.UTC(completedAt.getUTCFullYear() - persona.age, 5, 15),
      );
      await prisma.onboardingProfile.upsert({
        where: { userId: user.id },
        create: {
          userId: user.id,
          birthDate,
          genderIdentity: persona.gender,
          interestedIn: persona.interestedIn,
          datingIntentions: ["something_serious", "open_to_anything"],
          vibeType: persona.vibe,
          vibeTypes: persona.vibe ? [persona.vibe] : [],
          idealFriday: persona.friday,
          idealFridays: persona.friday ? [persona.friday] : [],
          interests: persona.interests,
          musicGenres: persona.genres,
          favoriteArtists: [],
          currentEra: persona.era,
          currentEras: persona.era ? [persona.era] : [],
          dealbreakers: ["kindness", "good_communication"],
          preferredDistanceKm: 100,
          onlyShowPeopleNearby: false,
          locationPermissionGranted: true,
          latitude: fixture.latitude + ((index % 5) - 2) * 0.006,
          longitude: fixture.longitude + ((index % 4) - 1.5) * 0.006,
          completedAt,
        },
        update: {
          birthDate,
          genderIdentity: persona.gender,
          interestedIn: persona.interestedIn,
          datingIntentions: ["something_serious", "open_to_anything"],
          vibeType: persona.vibe,
          vibeTypes: persona.vibe ? [persona.vibe] : [],
          idealFriday: persona.friday,
          idealFridays: persona.friday ? [persona.friday] : [],
          interests: persona.interests,
          musicGenres: persona.genres,
          favoriteArtists: [],
          currentEra: persona.era,
          currentEras: persona.era ? [persona.era] : [],
          dealbreakers: ["kindness", "good_communication"],
          preferredDistanceKm: 100,
          onlyShowPeopleNearby: false,
          locationPermissionGranted: true,
          latitude: fixture.latitude + ((index % 5) - 2) * 0.006,
          longitude: fixture.longitude + ((index % 4) - 1.5) * 0.006,
          completedAt,
        },
      });

      const profile = await prisma.profile.upsert({
        where: { userId: user.id },
        create: {
          userId: user.id,
          bio: persona.bio,
          location: fixture.city,
          education: persona.fieldOfStudy,
          fieldOfStudy: persona.fieldOfStudy,
          jobTitle: persona.jobTitle,
          heightCm: 160 + ((index * 7) % 29),
          languages: ["English", "Telugu"],
          showProfile: true,
          showDistance: true,
          showOnlineStatus: true,
          verificationStatus: "not_started",
          completedAt,
        },
        update: {
          bio: persona.bio,
          location: fixture.city,
          education: persona.fieldOfStudy,
          fieldOfStudy: persona.fieldOfStudy,
          jobTitle: persona.jobTitle,
          heightCm: 160 + ((index * 7) % 29),
          languages: ["English", "Telugu"],
          showProfile: true,
          showDistance: true,
          showOnlineStatus: true,
          completedAt,
        },
      });

      await prisma.profilePhoto.deleteMany({
        where: {
          profileId: profile.id,
          publicId: { startsWith: PHOTO_PREFIX },
        },
      });
      await prisma.profilePhoto.createMany({
        data: Array.from({ length: 4 }, (_, position) => {
          const imageId = ((persona.image - 1 + position * 10) % 70) + 1;
          const publicId = `${PHOTO_PREFIX}${idSuffix}-${position + 1}`;
          return {
            profileId: profile.id,
            publicId,
            secureUrl: `https://i.pravatar.cc/900?img=${imageId}`,
            width: 900,
            height: 1200,
            position,
          };
        }),
      });

      await prisma.profilePrompt.deleteMany({
        where: { profileId: profile.id },
      });
      await prisma.profilePrompt.createMany({
        data: persona.prompts.map(([question, answer], position) => ({
          profileId: profile.id,
          question,
          answer,
          position,
        })),
      });

      console.log(`Seeded ${persona.gender} demo profile: ${persona.username}`);
    }
    console.log(
      "Seeded 10 boys and 10 girls. Existing non-demo users were untouched.",
    );
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
