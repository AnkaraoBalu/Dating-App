const test = require("node:test");
const assert = require("node:assert/strict");
const {
  VibeRoomsGateway,
} = require("../dist/src/modules/vibe-rooms/vibe-rooms.gateway.js");
const {
  VibeRoomsController,
} = require("../dist/src/modules/vibe-rooms/vibe-rooms.controller.js");

function socket(userId) {
  const emitted = [];
  const rooms = new Set();
  return {
    data: { userId },
    emitted,
    rooms,
    emit: (event, payload) => emitted.push({ event, payload }),
    join: async (room) => rooms.add(room),
    leave: async (room) => rooms.delete(room),
  };
}

test("only active members can join a room's live chat", async () => {
  const gateway = new VibeRoomsGateway({
    assertMember: async (userId) => {
      if (userId !== "member") throw new Error("not a member");
    },
  });
  const member = socket("member");
  const outsider = socket("outsider");
  await gateway.join(member, { roomId: "r1" });
  await gateway.join(outsider, { roomId: "r1" });
  assert.deepEqual([...member.rooms], ["vibe:r1"]);
  assert.equal(member.emitted[0].event, "vibe:joined");
  assert.equal(outsider.rooms.size, 0);
  assert.equal(outsider.emitted[0].event, "vibe:error");
});

test("unauthenticated sockets are ignored", async () => {
  let checked = false;
  const gateway = new VibeRoomsGateway({
    assertMember: async () => {
      checked = true;
    },
  });
  const anonymous = socket(undefined);
  await gateway.join(anonymous, { roomId: "r1" });
  assert.equal(checked, false);
  assert.equal(anonymous.rooms.size, 0);
});

test("room messages are pushed with a viewer-specific isMe", async () => {
  const gateway = new VibeRoomsGateway({});
  const sockets = [socket("arav"), socket("zoya")];
  let requestedRoom;
  gateway.server = {
    in: (room) => {
      requestedRoom = room;
      return { fetchSockets: async () => sockets };
    },
  };
  await gateway.broadcastMessage("r1", { id: "m1", senderId: "arav" });
  assert.equal(requestedRoom, "vibe:r1");
  assert.deepEqual(
    sockets.map((s) => [s.emitted[0].event, s.emitted[0].payload.isMe]),
    [
      ["vibe:message", true],
      ["vibe:message", false],
    ],
  );
  assert.equal(sockets[1].emitted[0].payload.roomId, "r1");
});

test("a broadcast failure does not fail the send", async () => {
  const gateway = new VibeRoomsGateway({});
  gateway.logger = { error() {} };
  gateway.server = {
    in: () => ({
      fetchSockets: async () => {
        throw new Error("adapter down");
      },
    }),
  };
  await assert.doesNotReject(
    gateway.broadcastMessage("r1", { id: "m1", senderId: "arav" }),
  );
});

test("sending saves first, then broadcasts; leaving stops live delivery", async () => {
  const calls = [];
  const saved = { id: "m1", senderId: "arav", text: "Hi", isMe: true };
  const controller = new VibeRoomsController(
    { leave: async () => ({ id: "r1" }) },
    {
      send: async () => {
        calls.push("save");
        return saved;
      },
      databaseUserId: async () => "arav",
    },
    {
      broadcastMessage: async (roomId, message) =>
        calls.push(["broadcast", roomId, message.id]),
      removeMember: (roomId, userId) => calls.push(["remove", roomId, userId]),
    },
    { consume: () => {} },
  );
  const request = { auth: { userId: "clerk-arav" } };
  assert.equal(
    await controller.sendMessage(request, "r1", {
      clientMessageId: "c1",
      text: "Hi",
    }),
    saved,
  );
  await controller.leave(request, "r1");
  assert.deepEqual(calls, [
    "save",
    ["broadcast", "r1", "m1"],
    ["remove", "r1", "arav"],
  ]);
});

test("removing a member targets their private room", () => {
  const gateway = new VibeRoomsGateway({});
  const left = [];
  gateway.server = {
    in: (room) => ({ socketsLeave: (target) => left.push([room, target]) }),
  };
  gateway.removeMember("r1", "zoya");
  assert.deepEqual(left, [["user:zoya", "vibe:r1"]]);
});
