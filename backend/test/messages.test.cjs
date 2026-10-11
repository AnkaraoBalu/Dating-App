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
    message: { findMany: async () => [row] },
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
