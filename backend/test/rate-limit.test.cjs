const test = require("node:test");
const assert = require("node:assert/strict");
const {
  SendRateLimiter,
  TooManyMessagesException,
} = require("../dist/src/modules/rate-limit/send-rate-limiter.service.js");
const {
  MessagesGateway,
} = require("../dist/src/modules/messages/messages.gateway.js");
const {
  VibeRoomsController,
} = require("../dist/src/modules/vibe-rooms/vibe-rooms.controller.js");

function limiterAt(clock) {
  const limiter = new SendRateLimiter();
  limiter.now = () => clock.now;
  return limiter;
}

test("allows a burst of 8, then asks to wait until the oldest ages out", () => {
  const clock = { now: 0 };
  const limiter = limiterAt(clock);
  for (let i = 0; i < 8; i++) {
    clock.now = i * 100;
    limiter.consume("chat:arav");
  }
  clock.now = 1_000;
  assert.throws(
    () => limiter.consume("chat:arav"),
    (error) =>
      error instanceof TooManyMessagesException &&
      error.getStatus() === 429 &&
      error.retryAfterSeconds === 4 &&
      /too fast/.test(error.message),
  );
  clock.now = 5_000; // the first send (t=0) has left the 5 s window
  assert.doesNotThrow(() => limiter.consume("chat:arav"));
  limiter.onModuleDestroy();
});

test("caps sustained sending at 60 per minute", () => {
  const clock = { now: 0 };
  const limiter = limiterAt(clock);
  for (let i = 0; i < 60; i++) {
    clock.now = i * 900; // under the burst limit, 54 s in total
    limiter.consume("vibe:zoya");
  }
  clock.now = 54_500;
  assert.throws(() => limiter.consume("vibe:zoya"), TooManyMessagesException);
  clock.now = 60_000;
  assert.doesNotThrow(() => limiter.consume("vibe:zoya"));
  limiter.onModuleDestroy();
});

test("users and channels have separate allowances; rejected sends don't count", () => {
  const clock = { now: 0 };
  const limiter = limiterAt(clock);
  for (let i = 0; i < 8; i++) limiter.consume("chat:arav");
  for (let i = 0; i < 5; i++) {
    assert.throws(() => limiter.consume("chat:arav"));
  }
  assert.doesNotThrow(() => limiter.consume("chat:zoya"));
  assert.doesNotThrow(() => limiter.consume("vibe:arav"));
  clock.now = 5_000;
  assert.doesNotThrow(() => limiter.consume("chat:arav"));
  limiter.onModuleDestroy();
});

test("a limited socket send is rejected with the wait time and not saved", async () => {
  let saved = false;
  const limiter = new SendRateLimiter();
  limiter.consume = () => {
    throw new TooManyMessagesException(3);
  };
  const gateway = new MessagesGateway(
    {},
    {},
    {
      sendMessage: async () => {
        saved = true;
      },
    },
    undefined,
    limiter,
  );
  const emitted = [];
  await gateway.sendMessage(
    {
      data: { userId: "arav" },
      emit: (event, payload) => emitted.push({ event, payload }),
    },
    { conversationId: "c1", clientMessageId: "m1", text: "Hi" },
  );
  limiter.onModuleDestroy();
  assert.equal(saved, false);
  assert.equal(emitted[0].event, "message:error");
  assert.equal(emitted[0].payload.clientMessageId, "m1");
  assert.equal(emitted[0].payload.retryAfterSeconds, 3);
  assert.match(emitted[0].payload.message, /Try again in 3 seconds/);
});

test("a limited Vibe room send returns 429 before saving", async () => {
  let saved = false;
  const controller = new VibeRoomsController(
    {},
    {
      databaseUserId: async () => "arav",
      send: async () => {
        saved = true;
      },
    },
    { broadcastMessage: async () => {} },
    {
      consume: (key) => {
        assert.equal(key, "vibe:arav");
        throw new TooManyMessagesException(2);
      },
    },
  );
  await assert.rejects(
    controller.sendMessage({ auth: { userId: "clerk-arav" } }, "r1", {
      clientMessageId: "c1",
      text: "Hi",
    }),
    (error) => error.getStatus() === 429,
  );
  assert.equal(saved, false);
});
