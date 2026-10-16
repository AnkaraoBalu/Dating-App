const test = require("node:test");
const assert = require("node:assert/strict");
const {
  SafetyService,
} = require("../dist/src/modules/safety/safety.service.js");
const {
  ProfileConnectionsService,
} = require("../dist/src/modules/profile-setup/profile-connections.service.js");

function setup({ users = ["me", "them"] } = {}) {
  const log = [];
  const tx = {
    profileBlock: { upsert: async (args) => log.push(["block", args.create]) },
    profileLike: {
      deleteMany: async (args) => log.push(["deleteLikes", args.where]),
    },
    conversation: {
      deleteMany: async (args) => log.push(["deleteConversation", args.where]),
    },
    profilePass: { upsert: async (args) => log.push(["pass", args.create]) },
    profileReport: {
      create: async ({ data }) => {
        log.push(["report", data]);
        return { id: "report-1", createdAt: new Date(0), ...data };
      },
    },
  };
  const prisma = {
    user: {
      findUnique: async ({ where }) => {
        const id = where.clerkUserId ? "me" : where.id;
        return users.includes(id) ? { id, username: `${id}-name` } : null;
      },
    },
    $transaction: async (fn) => fn(tx),
  };
  const notified = [];
  const mails = [];
  const realtime = {
    notifyUser: (userId, event) => notified.push([userId, event]),
  };
  const mail = {
    teamInbox: "team@just2.test",
    send: async (message) => {
      mails.push(message);
      return true;
    },
  };
  return {
    safety: new SafetyService(prisma, realtime, mail),
    log,
    notified,
    mails,
  };
}

test("block ends the match and chat for both people and records the block", async () => {
  const { safety, log, notified } = setup();
  assert.deepEqual(await safety.block("clerk-me", "them"), { blocked: true });
  assert.deepEqual(log, [
    ["block", { blockerId: "me", blockedId: "them" }],
    [
      "deleteLikes",
      {
        OR: [
          { fromUserId: "me", toUserId: "them" },
          { fromUserId: "them", toUserId: "me" },
        ],
      },
    ],
    ["deleteConversation", { userOneId: "me", userTwoId: "them" }],
  ]);
  assert.deepEqual(notified, [
    ["me", "inbox:changed"],
    ["them", "inbox:changed"],
  ]);
});

test("unmatch removes the connection and hides both from each other without a block", async () => {
  const { safety, log } = setup();
  assert.deepEqual(await safety.unmatch("clerk-me", "them"), {
    unmatched: true,
  });
  assert.equal(
    log.some(([kind]) => kind === "block"),
    false,
  );
  assert.deepEqual(
    log.filter(([kind]) => kind === "pass").map(([, data]) => data),
    [
      { fromUserId: "me", toUserId: "them" },
      { fromUserId: "them", toUserId: "me" },
    ],
  );
  assert.ok(log.some(([kind]) => kind === "deleteConversation"));
});

test("a report is saved, blocks the member and emails the team", async () => {
  const { safety, log, mails } = setup();
  assert.deepEqual(
    await safety.report("clerk-me", "them", {
      reason: "harassment",
      details: "  Rude messages  ",
      source: "chat",
    }),
    { reported: true, blocked: true },
  );
  assert.deepEqual(log[0], [
    "report",
    {
      reporterId: "me",
      reportedUserId: "them",
      reason: "harassment",
      details: "Rude messages",
      source: "chat",
    },
  ]);
  assert.ok(log.some(([kind]) => kind === "block"));
  assert.equal(mails.length, 1);
  assert.equal(mails[0].to, "team@just2.test");
  assert.match(mails[0].subject, /harassment/);
  assert.match(mails[0].text, /Reported member: them-name \(them\)/);
  assert.match(mails[0].text, /Reported by: me-name \(me\)/);
  assert.match(mails[0].text, /Rude messages/);
});

test("safety actions reject unknown members and your own profile", async () => {
  const { safety } = setup({ users: ["me"] });
  await assert.rejects(safety.block("clerk-me", "ghost"), { status: 404 });
  await assert.rejects(safety.block("clerk-me", "me"), { status: 400 });
});

test("blocked peers are found in both directions", async () => {
  const prisma = {
    profileBlock: {
      findMany: async () => [
        { blockerId: "me", blockedId: "a" },
        { blockerId: "b", blockedId: "me" },
      ],
    },
  };
  assert.deepEqual(await SafetyService.blockedPeerIds(prisma, "me"), [
    "a",
    "b",
  ]);
});

test("a blocked member cannot like the person who blocked them", async () => {
  const connections = new ProfileConnectionsService(
    {
      user: {
        findUnique: async ({ where }) =>
          where.clerkUserId
            ? { id: "them" }
            : { id: where.id, profile: { completedAt: new Date() } },
      },
      profileBlock: { findFirst: async () => ({ id: "block-1" }) },
    },
    {},
  );
  await assert.rejects(connections.like("clerk-them", "me"), { status: 404 });
});
