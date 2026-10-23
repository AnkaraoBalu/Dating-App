const test = require("node:test");
const assert = require("node:assert/strict");
const {
  VibeRoomsService,
} = require("../dist/src/modules/vibe-rooms/vibe-rooms.service.js");
const {
  VibeRoomsController,
} = require("../dist/src/modules/vibe-rooms/vibe-rooms.controller.js");

function service(viewerId, room, deleted) {
  const tx = {
    vibeRoom: {
      findUnique: async () => room,
      delete: async ({ where }) => deleted.push(where.id),
    },
    vibeRoomMember: {
      findMany: async () => [{ userId: "host" }, { userId: "asha" }],
    },
    vibeRoomMessage: {
      findMany: async () => [{ mediaPublicId: "voice/1" }],
    },
  };
  return new VibeRoomsService({
    user: { findUnique: async () => ({ id: viewerId }) },
    $transaction: async (work) => work(tx),
  });
}

test("the host deletes the room and gets its members and voice notes", async () => {
  const deleted = [];
  const result = await service("host", { hostUserId: "host" }, deleted).delete(
    "clerk-host",
    "r1",
  );
  assert.deepEqual(deleted, ["r1"]);
  assert.deepEqual(result, {
    memberIds: ["host", "asha"],
    mediaPublicIds: ["voice/1"],
  });
});

test("only the host can delete a room", async () => {
  const deleted = [];
  await assert.rejects(
    service("asha", { hostUserId: "host" }, deleted).delete("clerk-asha", "r1"),
    { status: 403 },
  );
  assert.deepEqual(deleted, []);
});

test("deleting a missing room is a 404", async () => {
  await assert.rejects(service("host", null, []).delete("clerk-host", "r1"), {
    status: 404,
  });
});

test("after a delete, viewers, voice, media and Chat lists are cleaned up", async () => {
  const calls = [];
  const controller = new VibeRoomsController(
    {
      delete: async () => ({
        memberIds: ["host", "asha"],
        mediaPublicIds: ["voice/1"],
      }),
    },
    { destroyMedia: async (ids) => calls.push(["media", ids]) },
    { roomDeleted: (roomId) => calls.push(["live", roomId]) },
    {},
    {},
    { notifyUser: (userId, event) => calls.push(["inbox", userId, event]) },
    {},
    { closeRoom: async (roomId) => calls.push(["voice", roomId]) },
  );
  assert.deepEqual(
    await controller.remove({ auth: { userId: "clerk-host" } }, "r1"),
    { deleted: true },
  );
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls, [
    ["live", "r1"],
    ["voice", "r1"],
    ["media", ["voice/1"]],
    ["inbox", "host", "inbox:changed"],
    ["inbox", "asha", "inbox:changed"],
  ]);
});

function editService(viewerId, room, updates) {
  const tx = {
    vibeRoom: {
      findUnique: async () => room,
      update: async ({ data }) => {
        updates.push(data);
        throw new Error("stop after update");
      },
    },
  };
  return new VibeRoomsService({
    user: { findUnique: async () => ({ id: viewerId }) },
    $transaction: async (work) => work(tx),
  });
}

test("the host can rename a room and take it live", async () => {
  const updates = [];
  await assert.rejects(
    editService("host", { hostUserId: "host" }, updates).update(
      "clerk-host",
      "r1",
      { title: "  Sunday coffee ", isLive: true },
    ),
    /stop after update/,
  );
  assert.equal(updates[0].title, "Sunday coffee");
  assert.equal(updates[0].isLive, true);
  assert.equal(updates[0].scheduledFor, null);
  assert.equal(updates[0].description, undefined);
});

test("only the host can edit a room", async () => {
  const updates = [];
  await assert.rejects(
    editService("asha", { hostUserId: "host" }, updates).update(
      "clerk-asha",
      "r1",
      { isLive: true },
    ),
    { status: 403 },
  );
  assert.deepEqual(updates, []);
});
