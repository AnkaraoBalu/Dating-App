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
    undefined,
    undefined,
    { leaveRoom: async () => [] },
    {
      removeParticipant: async (roomId, userId) =>
        calls.push(["voice-remove", roomId, userId]),
    },
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
    ["voice-remove", "r1", "arav"],
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

test("broadcasting reports which members saw the message live", async () => {
  const gateway = new VibeRoomsGateway({});
  gateway.server = {
    in: () => ({ fetchSockets: async () => [socket("arav"), socket("zoya")] }),
  };
  const viewers = await gateway.broadcastMessage("r1", {
    id: "m1",
    senderId: "arav",
  });
  assert.deepEqual([...viewers].sort(), ["arav", "zoya"]);
});

function joinController(joinResult, calls) {
  return new VibeRoomsController(
    { joinWithDetails: async () => joinResult },
    {
      recordJoin: async (userId, roomId) => {
        calls.push(["line", roomId, userId]);
        return { id: "j1", senderId: userId, kind: "join" };
      },
      activeMemberIds: async () => ["host", "asha"],
    },
    {
      broadcastMessage: async (roomId, message) => {
        calls.push(["broadcast", roomId, message.kind]);
        return new Set();
      },
    },
    { consume: () => {} },
    {
      vibeRoomJoined: async (hostId, room) =>
        calls.push(["notifyHost", hostId, room.joinerId]),
    },
    { notifyUser: (userId, event) => calls.push(["inbox", userId, event]) },
  );
}

test("a new join adds a chat line, refreshes Chat lists and tells the host", async () => {
  const calls = [];
  const room = { id: "r1" };
  const controller = joinController(
    {
      newlyJoined: true,
      room,
      userId: "asha",
      hostUserId: "host",
      title: "Coffee",
    },
    calls,
  );
  assert.equal(
    await controller.join({ auth: { userId: "clerk-asha" } }, "r1"),
    room,
  );
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls, [
    ["line", "r1", "asha"],
    ["broadcast", "r1", "join"],
    ["notifyHost", "host", "asha"],
    ["inbox", "host", "inbox:changed"],
    ["inbox", "asha", "inbox:changed"],
  ]);
});

test("re-joining as an existing member stays quiet", async () => {
  const calls = [];
  const controller = joinController(
    {
      newlyJoined: false,
      room: { id: "r1" },
      userId: "asha",
      hostUserId: "host",
      title: "Coffee",
    },
    calls,
  );
  await controller.join({ auth: { userId: "clerk-asha" } }, "r1");
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls, []);
});

test("members away from the room get a push; everyone's Chat list refreshes", async () => {
  let excluded;
  let pushed;
  const refreshed = [];
  const controller = new VibeRoomsController(
    {},
    {
      databaseUserId: async () => "arav",
      send: async () => ({ id: "m1", senderId: "arav", text: "Who's in?" }),
      pushRecipients: async (roomId, exclude) => {
        excluded = [...exclude];
        return { title: "Coffee", userIds: ["meera"] };
      },
      activeMemberIds: async () => ["arav", "zoya", "meera"],
    },
    { broadcastMessage: async () => new Set(["arav", "zoya"]) },
    { consume: () => {} },
    {
      vibeRoomMessage: async (userIds, message) => {
        pushed = [userIds, message.title, message.text];
      },
    },
    { notifyUser: (userId) => refreshed.push(userId) },
  );
  await controller.sendMessage({ auth: { userId: "clerk-arav" } }, "r1", {
    clientMessageId: "c1",
    text: "Who's in?",
  });
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual([...new Set(excluded)], ["arav", "zoya"]);
  assert.deepEqual(pushed, [["meera"], "Coffee", "Who's in?"]);
  assert.deepEqual(refreshed, ["arav", "zoya", "meera"]);
});
