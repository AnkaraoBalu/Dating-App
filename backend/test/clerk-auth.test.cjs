const test = require("node:test");
const assert = require("node:assert/strict");
const { generateKeyPairSync, sign } = require("node:crypto");
const { ConfigService } = require("@nestjs/config");
const {
  ClerkAuthGuard,
} = require("../dist/src/modules/auth/clerk-auth.guard.js");
const { UsersService } = require("../dist/src/modules/users/users.service.js");
const {
  createDemoSessionToken,
} = require("../dist/src/modules/demo-auth/demo-session.js");

const { privateKey, publicKey } = generateKeyPairSync("rsa", {
  modulusLength: 2048,
});
const jwk = {
  ...publicKey.export({ format: "jwk" }),
  kid: "auth-test-key",
  alg: "RS256",
  use: "sig",
};
const demoSecret = "test-only-demo-secret-with-at-least-32-characters";
const config = (changes = {}) =>
  new ConfigService({
    NODE_ENV: "development",
    CLERK_SECRET_KEY: "sk_test_auth_fixture",
    DEMO_AUTH_ENABLED: "true",
    DEMO_AUTH_SECRET: demoSecret,
    ...changes,
  });
function sessionToken(changes = {}, key = privateKey) {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(
    JSON.stringify({ alg: "RS256", typ: "JWT", kid: jwk.kid }),
  ).toString("base64url");
  const payload = Buffer.from(
    JSON.stringify({
      sub: "user_real_fixture",
      sid: "sess_fixture",
      iss: "https://auth-test.clerk.accounts.dev",
      iat: now,
      nbf: now - 5,
      exp: now + 60,
      ...changes,
    }),
  ).toString("base64url");
  const input = `${header}.${payload}`;
  return `${input}.${sign("RSA-SHA256", Buffer.from(input), key).toString("base64url")}`;
}
function requestContext(token) {
  const request = {
    method: "GET",
    path: "/api/v1/users/me",
    headers: token ? { authorization: `Bearer ${token}` } : {},
  };
  return { request, switchToHttp: () => ({ getRequest: () => request }) };
}

test("real Clerk authentication and demo isolation", async (t) => {
  // Exercise Clerk's actual signature verifier using an offline JWKS fixture.
  const previousNodeEnv = process.env.NODE_ENV;
  process.env.NODE_ENV = "test";
  t.after(() => {
    if (previousNodeEnv === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = previousNodeEnv;
  });
  t.mock.method(globalThis, "fetch", async (url) => {
    assert.equal(String(url), "https://api.clerk.com/v1/jwks");
    return Response.json({ keys: [jwk] });
  });

  await t.test(
    "valid Clerk session works while demo auth is enabled",
    async () => {
      const context = requestContext(sessionToken());
      assert.equal(
        await new ClerkAuthGuard(config()).canActivate(context),
        true,
      );
      assert.deepEqual(context.request.auth, { userId: "user_real_fixture" });
    },
  );
  await t.test("expired Clerk session is rejected", async () => {
    await assert.rejects(
      new ClerkAuthGuard(config()).canActivate(
        requestContext(sessionToken({ exp: 1 })),
      ),
      { status: 401 },
    );
  });
  await t.test("forged Clerk session is rejected", async () => {
    const otherKey = generateKeyPairSync("rsa", {
      modulusLength: 2048,
    }).privateKey;
    await assert.rejects(
      new ClerkAuthGuard(config()).canActivate(
        requestContext(sessionToken({}, otherKey)),
      ),
      { status: 401 },
    );
  });
  await t.test("missing session is rejected", async () => {
    await assert.rejects(
      new ClerkAuthGuard(config()).canActivate(requestContext()),
      { status: 401 },
    );
  });
  await t.test(
    "production accepts demo sessions only with the explicit opt-in",
    async () => {
      const token = createDemoSessionToken("demo_matchify_maya", demoSecret);
      const context = requestContext(token);
      assert.equal(
        await new ClerkAuthGuard(
          config({
            NODE_ENV: "production",
            DEMO_AUTH_ALLOW_IN_PRODUCTION: "true",
          }),
        ).canActivate(context),
        true,
      );
      assert.equal(context.request.auth.userId, "demo_matchify_maya");
      await assert.rejects(
        new ClerkAuthGuard(
          config({
            NODE_ENV: "production",
            DEMO_AUTH_ALLOW_IN_PRODUCTION: "false",
          }),
        ).canActivate(requestContext(token)),
        { status: 401 },
      );
    },
  );
  await t.test(
    "demo session works only in explicitly enabled development",
    async () => {
      const token = createDemoSessionToken("demo_matchify_maya", demoSecret);
      const context = requestContext(token);
      assert.equal(
        await new ClerkAuthGuard(config()).canActivate(context),
        true,
      );
      assert.equal(context.request.auth.userId, "demo_matchify_maya");
      for (const changes of [
        { NODE_ENV: "production" },
        { DEMO_AUTH_ENABLED: "false" },
        { DEMO_AUTH_ALLOW_IN_PRODUCTION: "true", DEMO_AUTH_ENABLED: "false" },
      ]) {
        await assert.rejects(
          new ClerkAuthGuard(config(changes)).canActivate(
            requestContext(token),
          ),
          { status: 401 },
        );
      }
    },
  );
});

test("real-user sync uses Clerk identity and preserves app profile data", async () => {
  let query;
  const service = new UsersService(
    {
      user: {
        upsert: async (args) => {
          query = args;
          return {
            id: "db-real-user",
            username: "App name",
            onboardingProfile: { completedAt: new Date() },
          };
        },
      },
    },
    config(),
  );
  service.clerk = {
    users: {
      getUser: async (id) => {
        assert.equal(id, "user_real_fixture");
        return {
          primaryEmailAddressId: "email_fixture",
          emailAddresses: [
            { id: "email_fixture", emailAddress: "real@example.test" },
          ],
          primaryPhoneNumberId: null,
          phoneNumbers: [],
          firstName: "Real",
          lastName: "User",
          imageUrl: "https://example.test/avatar.jpg",
        };
      },
    },
  };
  const user = await service.syncFromClerk("user_real_fixture");
  assert.deepEqual(query.where, { clerkUserId: "user_real_fixture" });
  assert.equal(query.create.email, "real@example.test");
  assert.equal(query.update.username, undefined);
  assert.equal(query.update.onboardingProfile, undefined);
  assert.equal(user.username, "App name");
  assert.ok(user.onboardingProfile.completedAt);
});
