const test = require("node:test");
const assert = require("node:assert/strict");
const {
  MessagesService,
} = require("../dist/src/modules/messages/messages.service.js");
const {
  MessagesGateway,
} = require("../dist/src/modules/messages/messages.gateway.js");
const conversation = {
  id: "conversation",
  userOneId: "arav",
  userTwoId: "zoya",
};
const row = {
  id: "reply",
  senderId: "arav",
  clientMessageId: "client-reply",
  conversationId: "conversation",
  text: "Reply",
  type: "text",
  savedInChat: false,
  createdAt: new Date(),
};

function prismaBase() {
  return {
    user: {
      findUnique: async ({ where }) => ({
        id: where.clerkUserId.replace("clerk-", ""),
      }),
    },
    conversation: { findUnique: async () => conversation },
    message: {
      findMany: async ({ where }) => (where.type === "expired" ? [] : [row]),
    },
  };
}

test("history ownership remains relative to the viewer after reopening", async () => {
  const service = new MessagesService(prismaBase());
  for (let reopen = 0; reopen < 2; reopen++) {
    const sender = await service.listMessages("clerk-arav", conversation.id);
    const receiver = await service.listMessages("clerk-zoya", conversation.id);
    assert.equal(sender.viewerId, "arav");
    assert.equal(sender.items[0].fromMe, true);
    assert.equal(receiver.items[0].fromMe, false);
  }
  await assert.rejects(
    service.listMessages("clerk-outsider", conversation.id),
    /not part/,
  );
});

test("socket fan-out identifies sender and receiver independently", async () => {
  const gateway = new MessagesGateway({}, {}, {});
  const delivered = [];
  gateway.server = {
    in: () => ({
      fetchSockets: async () =>
        ["arav", "zoya"].map((userId) => ({
          data: { userId },
          emit: (event, payload) => delivered.push({ userId, event, payload }),
        })),
    }),
  };
  await gateway.broadcastMessage(conversation.id, row);
  assert.equal(delivered[0].payload.fromMe, true);
  assert.equal(delivered[1].payload.fromMe, false);
});

test("broadcast failure cannot turn a persisted send into a send error", async () => {
  const gateway = new MessagesGateway({}, {}, { sendMessage: async () => row });
  gateway.logger = { error() {} };
  gateway.broadcastMessage = async () => {
    throw new Error("adapter unavailable");
  };
  const events = [];
  await gateway.sendMessage(
    {
      data: { userId: "arav" },
      emit: (event, payload) => events.push({ event, payload }),
    },
    {
      conversationId: conversation.id,
      clientMessageId: row.clientMessageId,
      text: row.text,
    },
  );
  assert.deepEqual(
    events.map((e) => e.event),
    ["message:sent"],
  );
  assert.equal(events[0].payload.message.senderId, "arav");
  assert.equal(events[0].payload.message.id, row.id);
});

test("simultaneous retries confirm the existing saved message", async () => {
  const prisma = prismaBase();
  let finds = 0;
  prisma.message.findUnique = async () => (++finds === 1 ? null : row);
  prisma.$transaction = async () => {
    throw { code: "P2002" };
  };
  const saved = await new MessagesService(prisma).sendMessage(
    "arav",
    conversation.id,
    row.clientMessageId,
    { text: row.text },
  );
  assert.equal(saved.id, row.id);
  assert.equal(finds, 2);
});

test("read resets lock the conversation and preserve unread messages after the snapshot", async () => {
  const prisma = prismaBase();
  const order = [];
  let updates;
  prisma.$transaction = async (fn) =>
    fn({
      $queryRaw: async () => order.push("lock"),
      message: {
        findFirst: async ({ where }) => {
          order.push("snapshot");
          assert.equal(where.senderId.not, "zoya");
          assert.ok(where.createdAt.lte instanceof Date);
          return { id: row.id };
        },
        updateMany: async ({ where }) =>
          assert.ok(where.createdAt.lte instanceof Date),
        count: async () => 1,
      },
      conversation: {
        update: async ({ data }) => {
          updates = data;
        },
      },
    });
  const receipt = await new MessagesService(prisma).markConversationRead(
    "clerk-zoya",
    conversation.id,
  );
  assert.deepEqual(order, ["lock", "snapshot"]);
  assert.deepEqual(updates, { userTwoUnreadCount: 1 });
  assert.equal(receipt.readerId, "zoya");
  assert.equal(receipt.unreadCount, 1);
});

test("leave expires only requested read incoming messages and scrubs content", async () => {
  const prisma = prismaBase();
  const records = [
    { ...row, id: "read", readAt: new Date(), mediaPublicId: "photo" },
    { ...row, id: "unread", readAt: null },
    { ...row, id: "own", senderId: "zoya", readAt: new Date() },
    { ...row, id: "other-chat", conversationId: "other", readAt: new Date() },
    { ...row, id: "not-loaded", readAt: new Date() },
    { ...row, id: "saved", readAt: new Date(), savedInChat: true },
  ];
  const matches = (w, r) =>
    r.conversationId === w.conversationId &&
    w.id.in.includes(r.id) &&
    r.senderId !== w.senderId.not &&
    r.readAt != null &&
    r.type !== w.type.not &&
    r.savedInChat === w.savedInChat;
  prisma.$transaction = async (work) =>
    work({
      $queryRaw: async () => [],
      message: {
        findMany: async ({ where }) => records.filter((r) => matches(where, r)),
        updateMany: async ({ where, data }) => {
          records
            .filter((r) => matches(where, r))
            .forEach((r) => Object.assign(r, data));
        },
      },
    });
  const service = new MessagesService(prisma);
  const ids = ["read", "unread", "own", "other-chat", "saved"];
  const result = await service.expireViewedMessages(
    "clerk-zoya",
    "conversation",
    ids,
  );
  assert.deepEqual(result.messageIds, ["read"]);
  assert.deepEqual(result.mediaPublicIds, ["photo"]);
  assert.equal(records[0].text, "");
  assert.equal(records[0].type, "expired");
  assert.equal(records[0].mediaUrl, null);
  assert.equal(records[1].text, "Reply");
  assert.equal(records[5].text, "Reply");
  assert.deepEqual(
    (await service.expireViewedMessages("clerk-zoya", "conversation", ids))
      .messageIds,
    [],
  );
  await assert.rejects(
    service.expireViewedMessages("clerk-outsider", "conversation", ids),
    /not part/,
  );
  await assert.rejects(
    service.expireViewedMessages("clerk-zoya", "conversation", [123]),
    /Invalid message/,
  );
});

test("either participant saves and unsaves under the expiry lock; expired content cannot be saved", async () => {
  const prisma = prismaBase();
  let saved = false;
  let expired = false;
  const calls = [];
  prisma.$transaction = async (work) =>
    work({
      $queryRaw: async () => calls.push("lock"),
      message: {
        findFirst: async ({ where }) => {
          calls.push("lookup");
          assert.equal(where.conversationId, "conversation");
          assert.equal(where.type.not, "expired");
          return expired ? null : row;
        },
        update: async ({ data }) => {
          saved = data.savedInChat;
        },
      },
    });
  const service = new MessagesService(prisma);
  const result = await service.setSavedInChat(
    "clerk-zoya",
    "conversation",
    row.id,
    true,
  );
  assert.equal(saved, true);
  assert.equal(result.savedInChat, true);
  await service.setSavedInChat("clerk-arav", "conversation", row.id, false);
  assert.equal(saved, false);
  assert.deepEqual(calls, ["lock", "lookup", "lock", "lookup"]);
  expired = true;
  await assert.rejects(
    service.setSavedInChat("clerk-zoya", "conversation", row.id, true),
    /no longer available/,
  );
  await assert.rejects(
    service.setSavedInChat("clerk-outsider", "conversation", row.id, true),
    /not part/,
  );
  await assert.rejects(
    service.setSavedInChat("clerk-zoya", "conversation", row.id, "true"),
    /Invalid saved/,
  );
});
