const test = require("node:test");
const assert = require("node:assert/strict");
const {
  MessagesController,
} = require("../dist/src/modules/messages/messages.controller.js");

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const request = { auth: { userId: "clerk-zoya" } };

function controller(calls) {
  return new MessagesController(
    {
      validateLeave: async (_user, _conversation, ids) => {
        if (!Array.isArray(ids)) throw new Error("Invalid message IDs.");
        return ids;
      },
      expireViewedMessages: async (_user, conversationId, ids) => {
        calls.push(["expire", conversationId, [...ids].sort()]);
        return { messageIds: ids, mediaPublicIds: [] };
      },
      markConversationRead: async () => ({}),
      listMessages: async () => ({ items: [] }),
    },
    {},
    { deleteExpiredMedia: async () => {} },
    {
      broadcastExpired: (id, payload) =>
        calls.push(["broadcast", id, payload.messageIds.length]),
      notifyInboxChanged: async () => {},
    },
    {},
  );
}

test.beforeEach(() => {
  MessagesController.expiryDelayMs = 30;
});
test.after(() => {
  MessagesController.expiryDelayMs = 60_000;
});

test("viewed messages disappear only after the delay", async () => {
  const calls = [];
  const result = await controller(calls).leaveConversation(request, "c1", [
    "m1",
  ]);
  assert.deepEqual(result, {
    conversationId: "c1",
    messageIds: [],
    expiresInMs: 30,
  });
  assert.deepEqual(calls, []);
  await wait(60);
  assert.deepEqual(calls, [
    ["expire", "c1", ["m1"]],
    ["broadcast", "c1", 1],
  ]);
});

test("reopening the chat within the delay keeps the messages", async () => {
  const calls = [];
  const chat = controller(calls);
  await chat.leaveConversation(request, "c1", ["m1"]);
  await chat.listMessages(request, "c1");
  await wait(60);
  assert.deepEqual(calls, []);
});

test("returning to an open chat (read) also cancels it", async () => {
  const calls = [];
  const chat = controller(calls);
  await chat.leaveConversation(request, "c1", ["m1"]);
  await chat.markConversationRead(request, "c1");
  await wait(60);
  assert.deepEqual(calls, []);
});

test("leaving twice merges the messages and restarts the minute", async () => {
  const calls = [];
  const chat = controller(calls);
  await chat.leaveConversation(request, "c1", ["m1"]);
  await wait(15);
  await chat.leaveConversation(request, "c1", ["m2"]);
  await wait(20);
  assert.deepEqual(calls, []);
  await wait(40);
  assert.deepEqual(calls[0], ["expire", "c1", ["m1", "m2"]]);
});

test("a bad leave request still fails immediately", async () => {
  await assert.rejects(
    controller([]).leaveConversation(request, "c1", "nope"),
    /Invalid message IDs/,
  );
});
