const test = require("node:test");
const assert = require("node:assert/strict");
const { CallsService } = require("../dist/src/modules/calls/calls.service");

const person = (id) => ({
  id,
  username: id,
  firstName: null,
  lastName: null,
  imageUrl: null,
  profile: null,
});

function setup({ status = "ringing", active = null } = {}) {
  const events = [];
  const call = {
    id: "c1",
    conversationId: "conv",
    callerId: "arav",
    calleeId: "zoya",
    status,
    createdAt: new Date(),
    answeredAt: null,
    endedAt: null,
    caller: person("arav"),
    callee: person("zoya"),
  };
  const prisma = {
    call: {
      findUnique: async () => call,
      findUniqueOrThrow: async () => call,
      findFirst: async () => active,
      findMany: async () => [],
      create: async () => call,
      updateMany: async ({ where, data }) => {
        const allowed = where.status?.in ?? [where.status];
        if (!allowed.includes(call.status)) return { count: 0 };
        Object.assign(call, data);
        return { count: 1 };
      },
    },
    $transaction: async (run) =>
      run({
        message: {
          create: async ({ data }) => {
            events.push(["chat", data.text]);
            return { ...data, id: "m1", createdAt: new Date(), readAt: null };
          },
        },
        conversation: {
          findUniqueOrThrow: async () => ({ userOneId: "arav" }),
          update: async () => events.push(["unread"]),
        },
      }),
  };
  const service = new CallsService(
    prisma,
    {
      configured: true,
      deleteRoom: async () => events.push(["close"]),
      joinToken: async () => ({ serverUrl: "wss://x", participantToken: "t" }),
      participantCount: async () => null,
    },
    {
      userId: async (clerkId) => clerkId,
      assertParticipant: async () => ({ userOneId: "arav", userTwoId: "zoya" }),
      messageResponse: (message) => message,
    },
    {
      broadcastMessage: async () => new Set(),
      announceNewMessage: async () => events.push(["push"]),
      notifyInboxChanged: async () => events.push(["inbox"]),
    },
    {
      notifyUser: (userId, event, payload) =>
        events.push([event, userId, payload.status ?? payload.callId]),
    },
    { incomingCall: async () => events.push(["ring-push"]) },
  );
  return { service, call, events };
}

test("a call finishes once even if timeout and hang-up race", async () => {
  const { service, call, events } = setup();
  await Promise.all([
    service.finish("c1", "missed"),
    service.finish("c1", "ended"),
  ]);
  assert.equal(call.status, "missed");
  assert.equal(events.filter(([kind]) => kind === "chat").length, 1);
  assert.deepEqual(
    events.filter(([kind]) => kind === "chat"),
    [["chat", "missed"]],
  );
  // A missed call counts as unread and pushes "Missed voice call".
  assert.ok(events.some(([kind]) => kind === "unread"));
  assert.ok(events.some(([kind]) => kind === "push"));
});

test("the caller hanging up while ringing cancels the call", async () => {
  const { service, call, events } = setup();
  const view = await service.end("arav", "c1");
  assert.equal(call.status, "cancelled");
  assert.equal(view.status, "cancelled");
  assert.deepEqual(
    events.filter(([kind]) => kind === "call:updated"),
    [
      ["call:updated", "arav", "cancelled"],
      ["call:updated", "zoya", "cancelled"],
    ],
  );
});

test("only the callee can answer, and only while it rings", async () => {
  const { service, call } = setup();
  await assert.rejects(service.accept("arav", "c1"), /Only the person/);
  const joined = await service.accept("zoya", "c1");
  assert.equal(call.status, "accepted");
  assert.equal(joined.participantToken, "t");
  assert.equal(joined.peer.name, "arav");
  await assert.rejects(service.accept("zoya", "c1"), /already ended/);
});

test("a completed call records its length without an unread badge", async () => {
  const { service, call, events } = setup({ status: "accepted" });
  call.answeredAt = new Date(Date.now() - 65_000);
  await service.end("zoya", "c1");
  assert.equal(call.status, "ended");
  assert.deepEqual(
    events.filter(([kind]) => kind === "chat"),
    [["chat", "completed"]],
  );
  assert.ok(!events.some(([kind]) => kind === "unread"));
  assert.ok(events.some(([kind]) => kind === "inbox"));
});

test("you cannot call someone who is already on a call", async () => {
  const { service } = setup({ active: { id: "other" } });
  await assert.rejects(service.start("arav", "conv"), /already on a call/);
});
