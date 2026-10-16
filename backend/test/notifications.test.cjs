const test = require("node:test");
const assert = require("node:assert/strict");
const {
  NotificationsService,
  messagePreview,
} = require("../dist/src/modules/notifications/notifications.service.js");
const {
  FirebasePushSender,
} = require("../dist/src/modules/notifications/firebase-push.sender.js");
const {
  MessagesGateway,
} = require("../dist/src/modules/messages/messages.gateway.js");
const {
  ProfileConnectionsService,
} = require("../dist/src/modules/profile-setup/profile-connections.service.js");

function prismaWithDevices(tokens, calls = []) {
  return {
    calls,
    user: {
      findUnique: async ({ where }) =>
        where.clerkUserId
          ? { id: where.clerkUserId.replace("clerk-", "") }
          : { username: where.id === "arav" ? "Aarav" : null, firstName: null },
    },
    pushDevice: {
      findMany: async () => tokens.map((token) => ({ token })),
      upsert: async (args) => calls.push(["upsert", args]),
      deleteMany: async (args) => calls.push(["deleteMany", args]),
    },
  };
}

function recordingSender(dead = []) {
  const sent = [];
  return {
    sent,
    send: async (tokens, message) => {
      sent.push({ tokens, message });
      return dead;
    },
  };
}

test("a phone is registered to whoever signed in on it last", async () => {
  const prisma = prismaWithDevices([]);
  const service = new NotificationsService(prisma, recordingSender());
  await service.registerDevice("clerk-zoya", "token-1", "android");
  const [, args] = prisma.calls[0];
  assert.deepEqual(args.where, { token: "token-1" });
  assert.equal(args.create.userId, "zoya");
  assert.equal(args.update.userId, "zoya");
  assert.equal(args.update.platform, "android");
});

test("removing a phone only removes it from the signed-in account", async () => {
  const prisma = prismaWithDevices([]);
  const service = new NotificationsService(prisma, recordingSender());
  await service.removeDevice("clerk-zoya", "token-1");
  assert.deepEqual(prisma.calls[0], [
    "deleteMany",
    { where: { token: "token-1", userId: "zoya" } },
  ]);
});

test("a message push names the sender, previews the text and groups by chat", async () => {
  const sender = recordingSender();
  const service = new NotificationsService(
    prismaWithDevices(["t1", "t2"]),
    sender,
  );
  await service.newMessage("zoya", {
    senderId: "arav",
    conversationId: "c1",
    type: "text",
    text: "  See you at 7?  ",
  });
  const { tokens, message } = sender.sent[0];
  assert.deepEqual(tokens, ["t1", "t2"]);
  assert.equal(message.title, "Aarav");
  assert.equal(message.body, "See you at 7?");
  assert.deepEqual(message.data, { type: "message", conversationId: "c1" });
  assert.equal(message.group, "conversation:c1");
});

test("likes stay anonymous; matches name the other member", async () => {
  const sender = recordingSender();
  const service = new NotificationsService(prismaWithDevices(["t1"]), sender);
  await service.newLike("zoya");
  await service.newMatch("zoya", "arav");
  assert.doesNotMatch(sender.sent[0].message.body, /Aarav/);
  assert.deepEqual(sender.sent[0].message.data, { type: "like" });
  assert.match(sender.sent[1].message.body, /You and Aarav liked each other/);
  assert.deepEqual(sender.sent[1].message.data, {
    type: "match",
    userId: "arav",
  });
});

test("tokens Firebase rejects for good are deleted", async () => {
  const prisma = prismaWithDevices(["live", "dead"]);
  const service = new NotificationsService(prisma, recordingSender(["dead"]));
  await service.newLike("zoya");
  assert.deepEqual(prisma.calls.at(-1), [
    "deleteMany",
    { where: { token: { in: ["dead"] } } },
  ]);
});

test("no phones means nothing is sent, and send failures never throw", async () => {
  const sender = recordingSender();
  await new NotificationsService(prismaWithDevices([]), sender).newLike("zoya");
  assert.equal(sender.sent.length, 0);
  const failing = new NotificationsService(prismaWithDevices(["t1"]), {
    send: async () => {
      throw new Error("FCM down");
    },
  });
  failing.logger = { error() {} };
  await assert.doesNotReject(failing.newLike("zoya"));
});

test("without a service account key, push is off and sends nothing", async () => {
  const sender = new FirebasePushSender({ get: () => undefined });
  sender.logger = { warn() {} };
  assert.deepEqual(
    await sender.send(["t1"], { title: "x", body: "y", data: {} }),
    [],
  );
});

test("message previews for each message type", () => {
  assert.equal(messagePreview("image", ""), "📷 Photo");
  assert.equal(messagePreview("image", "Sunset"), "📷 Sunset");
  assert.equal(messagePreview("location", ""), "📍 Shared a location");
  assert.equal(messagePreview("text", "x".repeat(200)).length, 148);
});

function gatewayWithRoom(sockets) {
  const pushed = [];
  const gateway = new MessagesGateway(
    {},
    {
      conversation: {
        findUnique: async () => ({ userOneId: "arav", userTwoId: "zoya" }),
      },
    },
    {},
    undefined,
    undefined,
    {
      newMessage: async (recipientId, message) =>
        pushed.push({ recipientId, message }),
    },
  );
  gateway.server = { in: () => ({ fetchSockets: async () => sockets }) };
  return { gateway, pushed };
}

const saved = { senderId: "arav", type: "text", text: "Hi" };

test("no push while the recipient is looking at the chat", async () => {
  const { gateway, pushed } = gatewayWithRoom([{ data: { userId: "zoya" } }]);
  await gateway.announceNewMessage("c1", saved);
  assert.equal(pushed.length, 0);
});

test("push when the recipient's chat is in the background or closed", async () => {
  const away = gatewayWithRoom([{ data: { userId: "zoya", away: true } }]);
  await away.gateway.announceNewMessage("c1", saved);
  assert.equal(away.pushed[0].recipientId, "zoya");
  const closed = gatewayWithRoom([{ data: { userId: "arav" } }]);
  await closed.gateway.announceNewMessage("c1", saved);
  assert.equal(closed.pushed[0].recipientId, "zoya");
  assert.equal(closed.pushed[0].message.conversationId, "c1");
});

test("the app reports a chat going to the background and back", () => {
  const { gateway } = gatewayWithRoom([]);
  const client = { data: {} };
  gateway.presence(client, { active: false });
  assert.equal(client.data.away, true);
  gateway.presence(client, { active: true });
  assert.equal(client.data.away, false);
});

function connections({ existing, mutual }) {
  const pushes = [];
  const prisma = {
    user: {
      findUnique: async ({ where }) =>
        where.clerkUserId
          ? { id: "arav" }
          : { id: where.id, profile: { completedAt: new Date() } },
    },
    profileBlock: { findFirst: async () => null },
    profileLike: {
      upsert: async () => ({}),
      findUnique: async ({ where }) =>
        where.fromUserId_toUserId.fromUserId === "arav"
          ? existing
            ? { id: "mine" }
            : null
          : mutual
            ? { id: "theirs" }
            : null,
    },
  };
  const service = new ProfileConnectionsService(prisma, {}, undefined, {
    newLike: async (to) => pushes.push(["like", to]),
    newMatch: async (to, other) => pushes.push(["match", to, other]),
  });
  return { service, pushes };
}

test("a new like pushes once; repeating it pushes nothing", async () => {
  const first = connections({ existing: false, mutual: false });
  await first.service.like("clerk-arav", "zoya");
  assert.deepEqual(first.pushes, [["like", "zoya"]]);
  const again = connections({ existing: true, mutual: false });
  await again.service.like("clerk-arav", "zoya");
  assert.deepEqual(again.pushes, []);
});

test("a new match pushes only the member who didn't just like", async () => {
  const { service, pushes } = connections({ existing: false, mutual: true });
  await service.like("clerk-arav", "zoya");
  assert.deepEqual(pushes, [["match", "zoya", "arav"]]);
});
