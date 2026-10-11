const test = require("node:test");
const assert = require("node:assert/strict");
const {
  RealtimeService,
} = require("../dist/src/modules/realtime/realtime.service.js");
const {
  MessagesGateway,
} = require("../dist/src/modules/messages/messages.gateway.js");
const {
  ProfileConnectionsService,
} = require("../dist/src/modules/profile-setup/profile-connections.service.js");

function recordingRealtime() {
  const delivered = [];
  const realtime = new RealtimeService();
  realtime.attach({
    to: (room) => ({
      emit: (event, payload) => delivered.push({ room, event, payload }),
    }),
  });
  return { realtime, delivered };
}

function likePrisma({ mutual }) {
  return {
    user: {
      findUnique: async ({ where }) =>
        where.clerkUserId
          ? { id: "arav" }
          : { id: where.id, profile: { completedAt: new Date() } },
    },
    profileLike: {
      upsert: async () => ({}),
      findUnique: async () => (mutual ? { id: "like-back" } : null),
    },
  };
}

test("events go to the user's private room and never throw without a server", () => {
  const { realtime, delivered } = recordingRealtime();
  realtime.notifyUser("zoya", "like:new");
  assert.deepEqual(delivered, [
    { room: "user:zoya", event: "like:new", payload: {} },
  ]);
  assert.doesNotThrow(() =>
    new RealtimeService().notifyUser("zoya", "like:new"),
  );
});

test("a one-sided like tells only the liked member", async () => {
  const { realtime, delivered } = recordingRealtime();
  const connections = new ProfileConnectionsService(
    likePrisma({ mutual: false }),
    {},
    realtime,
  );
  const result = await connections.like("clerk-arav", "zoya");
  assert.equal(result.isMatch, false);
  assert.deepEqual(
    delivered.map(({ room, event }) => [room, event]),
    [["user:zoya", "like:new"]],
  );
});

test("a mutual like tells each member who they matched with", async () => {
  const { realtime, delivered } = recordingRealtime();
  const connections = new ProfileConnectionsService(
    likePrisma({ mutual: true }),
    {},
    realtime,
  );
  const result = await connections.like("clerk-arav", "zoya");
  assert.equal(result.isMatch, true);
  assert.deepEqual(
    delivered.map(({ room, event, payload }) => [
      room,
      event,
      payload.userId,
      payload.initiatedByYou,
    ]),
    [
      ["user:zoya", "match:new", "arav", false],
      ["user:arav", "match:new", "zoya", true],
    ],
  );
});

test("an inbox change reaches both participants, even without the chat open", async () => {
  const { realtime, delivered } = recordingRealtime();
  const prisma = {
    conversation: {
      findUnique: async () => ({ userOneId: "arav", userTwoId: "zoya" }),
    },
  };
  const gateway = new MessagesGateway({}, prisma, {}, realtime);
  await gateway.notifyInboxChanged("conversation");
  assert.deepEqual(
    delivered.map(({ room, event, payload }) => [
      room,
      event,
      payload.conversationId,
    ]),
    [
      ["user:arav", "inbox:changed", "conversation"],
      ["user:zoya", "inbox:changed", "conversation"],
    ],
  );
});

test("a saved socket message announces the inbox change after confirming it", async () => {
  const { realtime, delivered } = recordingRealtime();
  const saved = { id: "m1", senderId: "arav", conversationId: "conversation" };
  const prisma = {
    conversation: {
      findUnique: async () => ({ userOneId: "arav", userTwoId: "zoya" }),
    },
  };
  const gateway = new MessagesGateway(
    {},
    prisma,
    { sendMessage: async () => saved },
    realtime,
  );
  gateway.server = { in: () => ({ fetchSockets: async () => [] }) };
  const sent = [];
  await gateway.sendMessage(
    { data: { userId: "arav" }, emit: (event) => sent.push(event) },
    { conversationId: "conversation", clientMessageId: "c1", text: "Hi" },
  );
  assert.deepEqual(sent, ["message:sent"]);
  assert.equal(
    delivered.filter(({ event }) => event === "inbox:changed").length,
    2,
  );
});
