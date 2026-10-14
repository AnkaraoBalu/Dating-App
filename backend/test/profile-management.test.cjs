const test = require("node:test");
const assert = require("node:assert/strict");
const { v2: cloudinary } = require("cloudinary");
const {
  ProfileSetupService,
} = require("../dist/src/modules/profile-setup/profile-setup.service.js");

const {
  ProfileRepository,
} = require("../dist/src/modules/profile-setup/profile.repository.js");
const {
  ProfileDiscoveryService,
} = require("../dist/src/modules/profile-setup/profile-discovery.service.js");
const {
  ProfilePhotosService,
} = require("../dist/src/modules/profile-setup/profile-photos.service.js");
const {
  ProfileConnectionsService,
} = require("../dist/src/modules/profile-setup/profile-connections.service.js");
function service(prisma) {
  const profiles = new ProfileRepository(prisma);
  const photos = new ProfilePhotosService(
    prisma,
    { getOrThrow: () => "test-only" },
    profiles,
  );
  const api = new ProfileSetupService(
    prisma,
    profiles,
    new ProfileDiscoveryService(prisma),
    photos,
    new ProfileConnectionsService(prisma, profiles),
  );
  api.repository = profiles;
  return api;
}
function candidate(changes = {}) {
  return {
    userId: "other",
    location: "Hyderabad",
    bio: "Hello",
    languages: [],
    showProfile: true,
    showDistance: true,
    showOnlineStatus: true,
    createdAt: new Date(),
    verificationStatus: "not_started",
    photos: [{ secureUrl: "https://example.test/photo.png" }],
    prompts: [],
    user: {
      username: "Member",
      firstName: "Clerk name",
      lastActiveAt: new Date(),
      onboardingProfile: {
        birthDate: new Date("2000-01-01"),
        genderIdentity: "woman",
        interestedIn: "men",
        interests: ["coffee"],
        musicGenres: [],
        favoriteArtists: [],
        latitude: 17.38,
        longitude: 78.48,
      },
    },
    ...changes,
  };
}
function discoveryMock(profiles, onboardingChanges = {}) {
  let query;
  return {
    prisma: {
      profileLike: { findMany: async () => [] },
      profilePass: { findMany: async () => [] },
      user: {
        findUnique: async () => ({
          id: "me",
          profile: { location: "Hyderabad" },
          onboardingProfile: {
            completedAt: new Date(),
            genderIdentity: "man",
            interestedIn: "women",
            interests: ["coffee"],
            musicGenres: [],
            favoriteArtists: [],
            preferredDistanceKm: 25,
            latitude: 17.38,
            longitude: 78.48,
            ...onboardingChanges,
          },
        }),
      },
      profile: {
        findMany: async (args) => {
          query = args;
          return profiles;
        },
      },
    },
    query: () => query,
  };
}

function locatedCandidate(id, latitude, longitude, location = "Hyderabad") {
  const profile = candidate({ userId: id, location });
  Object.assign(profile.user.onboardingProfile, { latitude, longitude });
  return profile;
}

test("discovery uses saved member coordinates and enforces radius in every mode", async () => {
  const mock = discoveryMock([
    locatedCandidate("near", 17.38, 78.48),
    locatedCandidate("far", 19.076, 72.8777, "Mumbai"),
    locatedCandidate("unknown", null, null),
  ]);
  for (const mode of ["for_you", "nearby", "trending", "online", "new"]) {
    const people = await service(mock.prisma).discover("clerk-me", {
      mode,
      radiusKm: 1,
    });
    assert.deepEqual(
      people.map((person) => person.id),
      ["near"],
    );
  }
});

test("travel city replaces the member location and uses radius rather than city text", async () => {
  const mock = discoveryMock([
    locatedCandidate("travel", 19.076, 72.8777, "Mumbai"),
    locatedCandidate("neighbor", 19.077, 72.878, "Different city label"),
    locatedCandidate("outside", 19.2, 72.8777, "Mumbai"),
    locatedCandidate("home", 17.38, 78.48),
  ]);
  for (const mode of ["for_you", "nearby"]) {
    const people = await service(mock.prisma).discover("clerk-me", {
      mode,
      location: " Mumbai ",
      radiusKm: 1,
    });
    assert.deepEqual(people.map((person) => person.id).sort(), [
      "neighbor",
      "travel",
    ]);
    assert.equal(people.find((person) => person.id === "travel").distanceKm, 0);
  }
});

test("saved city does not replace missing GPS in normal discovery", async () => {
  const mock = discoveryMock(
    [
      locatedCandidate("near", 17.385, 78.4867),
      locatedCandidate("far", 19.076, 72.8777),
    ],
    { latitude: null, longitude: null },
  );
  for (const mode of ["for_you", "nearby", "trending"]) {
    await assert.rejects(
      service(mock.prisma).discover("clerk-me", { mode, radiusKm: 1 }),
      /Enable location/,
    );
  }
});

test("nearby ranking uses exact distance without exposing hidden distances", async () => {
  const hidden = locatedCandidate("hidden-near", 17.38, 78.48);
  hidden.showDistance = false;
  const mock = discoveryMock([
    locatedCandidate("visible-far", 17.39, 78.48),
    hidden,
  ]);
  const people = await service(mock.prisma).discover("clerk-me", {
    mode: "nearby",
  });
  assert.deepEqual(
    people.map((person) => person.id),
    ["hidden-near", "visible-far"],
  );
  assert.equal(people[0].distanceKm, null);
  assert.equal(people[0].latitude, null);
  assert.equal(people[0].longitude, null);
  assert.equal(
    people.some((person) => "sortDistanceKm" in person),
    false,
  );
});

test("discovery uses the saved distance unless a radius is explicitly supplied", async () => {
  const mock = discoveryMock(
    [
      locatedCandidate("near", 17.38, 78.48),
      locatedCandidate("farther", 17.4, 78.48),
    ],
    { preferredDistanceKm: 1 },
  );
  const api = service(mock.prisma);
  assert.deepEqual(
    (await api.discover("clerk-me", {})).map((p) => p.id),
    ["near"],
  );
  assert.equal((await api.discover("clerk-me", { radiusKm: 5 })).length, 2);
});

test("explicit coordinates are used as a pair and unsupported travel cities fail clearly", async () => {
  const mock = discoveryMock([locatedCandidate("target", 0, 0)]);
  const api = service(mock.prisma);
  const people = await api.discover("clerk-me", {
    location: "Custom destination",
    latitude: 0,
    longitude: 0,
    radiusKm: 1,
  });
  assert.deepEqual(
    people.map((person) => person.id),
    ["target"],
  );
  await assert.rejects(
    api.discover("clerk-me", { latitude: 0 }),
    /both latitude and longitude/,
  );
  await assert.rejects(
    api.discover("clerk-me", { location: "Unknown" }),
    /supported travel city/,
  );
  await assert.rejects(
    api.discover("clerk-me", { location: "constructor" }),
    /supported travel city/,
  );
});

test("discovery excludes paused profiles at the database and hides distance/map coordinates", async () => {
  const mock = discoveryMock([candidate({ showDistance: false })]);
  const people = await service(mock.prisma).discover("clerk-me", {});
  assert.equal(mock.query().where.showProfile, true);
  assert.equal(people.length, 1);
  assert.equal(people[0].distanceKm, null);
  assert.equal(people[0].latitude, null);
  assert.equal(people[0].longitude, null);
  assert.equal(people[0].distance, "Hyderabad");
});

test("hidden online status excludes a member from online mode and online-only filters", async () => {
  const mock = discoveryMock([candidate({ showOnlineStatus: false })]);
  const api = service(mock.prisma);
  assert.deepEqual(await api.discover("clerk-me", { mode: "online" }), []);
  assert.deepEqual(await api.discover("clerk-me", { onlineOnly: true }), []);
  assert.equal((await api.discover("clerk-me", {}))[0].online, false);
});

test("insights count reciprocal likes once per outgoing connection", async () => {
  const calls = [];
  const api = service({
    user: { findUnique: async () => ({ id: "me" }) },
    profileLike: {
      count: async (args) => {
        calls.push(args);
        return calls.length;
      },
    },
  });
  assert.deepEqual(await api.insights("clerk-me"), {
    likesReceived: 1,
    likesSent: 2,
    matches: 3,
  });
  assert.deepEqual(calls[2].where, {
    fromUserId: "me",
    toUser: { likesSent: { some: { toUserId: "me" } } },
  });
});

test("replacing an owned photo keeps its ID and position without requiring an empty slot", async () => {
  const upload = cloudinary.uploader.upload_stream;
  const destroy = cloudinary.uploader.destroy;
  let mutation;
  const destroyed = [];
  cloudinary.uploader.upload_stream = (_, callback) => ({
    end: () =>
      callback(null, {
        public_id: "new-asset",
        secure_url: "https://example.test/new.png",
        width: 800,
        height: 800,
      }),
  });
  cloudinary.uploader.destroy = async (id) => {
    destroyed.push(id);
    return { result: "ok" };
  };
  try {
    const api = service({
      user: { findUnique: async () => ({ id: "me" }) },
      profilePhoto: {
        findFirst: async ({ where }) => {
          assert.deepEqual(where, { id: "photo", profile: { userId: "me" } });
          return { id: "photo", publicId: "old-asset", position: 3 };
        },
        update: async (args) => {
          mutation = args;
        },
      },
    });
    api.repository.get = async () => ({
      photos: [{ id: "photo", position: 3 }],
    });
    const buffer = Buffer.alloc(32);
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]).copy(buffer);
    const result = await api.replacePhoto("clerk-me", "photo", {
      buffer,
      size: buffer.length,
    });
    assert.equal(mutation.where.id, "photo");
    assert.equal(mutation.data.position, undefined);
    assert.equal(result.photos[0].position, 3);
    assert.deepEqual(destroyed, ["old-asset"]);
  } finally {
    cloudinary.uploader.upload_stream = upload;
    cloudinary.uploader.destroy = destroy;
  }
});

test("photo replacement rejects photos owned by someone else", async () => {
  const api = service({
    user: { findUnique: async () => ({ id: "me" }) },
    profilePhoto: { findFirst: async () => null },
  });
  const buffer = Buffer.alloc(32);
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]).copy(buffer);
  await assert.rejects(
    api.replacePhoto("clerk-me", "not-mine", { buffer, size: buffer.length }),
    /Photo not found/,
  );
});

const { UsersService } = require("../dist/src/modules/users/users.service.js");
test("chosen username updates only local username and preserves Clerk names", async () => {
  let saved;
  const api = new UsersService(
    {
      user: {
        update: async (args) => {
          saved = args;
          return { id: "user", username: args.data.username };
        },
      },
    },
    { getOrThrow: () => "sk_test_placeholder" },
  );
  api.syncFromClerk = async () => ({
    id: "user",
    firstName: "Clerk",
    lastName: "Name",
  });
  api.clerk = {
    users: {
      updateUser: () => {
        throw new Error("Clerk names must stay unchanged");
      },
    },
  };
  await api.updateName("clerk-user", { username: "  Aanya  " });
  assert.deepEqual(saved, {
    where: { id: "user" },
    data: { username: "Aanya" },
  });
  await assert.rejects(api.updateName("clerk-user", { username: "   " }));
});

test("delete account removes the member row, uploads and Clerk user", async () => {
  const calls = [];
  const api = new UsersService(
    {
      user: {
        findUnique: async () => ({ id: "user-1" }),
        delete: async (args) => calls.push(["db", args.where.id]),
      },
    },
    { getOrThrow: () => "placeholder" },
  );
  api.deleteUploads = async (userId) => calls.push(["uploads", userId]);
  api.clerk = {
    users: { deleteUser: async (id) => calls.push(["clerk", id]) },
  };
  assert.deepEqual(await api.deleteAccount("clerk-user"), { deleted: true });
  assert.deepEqual(calls, [
    ["db", "user-1"],
    ["uploads", "user-1"],
    ["clerk", "clerk-user"],
  ]);
});

test("delete account retry still removes Clerk user and ignores Clerk 404", async () => {
  const calls = [];
  const api = new UsersService(
    { user: { findUnique: async () => null } },
    { getOrThrow: () => "placeholder" },
  );
  api.clerk = {
    users: {
      deleteUser: async (id) => {
        calls.push(id);
        throw Object.assign(new Error("not found"), { status: 404 });
      },
    },
  };
  assert.deepEqual(await api.deleteAccount("clerk-user"), { deleted: true });
  assert.deepEqual(calls, ["clerk-user"]);
});
