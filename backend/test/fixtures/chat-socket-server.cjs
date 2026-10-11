// Local regression fixture: no database, Clerk, or external network required.
const http = require("node:http");
const { Server } = require("socket.io");
const messages = [];
const authTokens = [];
let historyDelay = 0;
const server = http.createServer(async (req, res) => {
  const viewerId = (req.headers.authorization || "")
    .replace("Bearer ", "")
    .split(":")[0];
  res.setHeader("Content-Type", "application/json");
  if (req.url === "/fixture/delay-history") {
    historyDelay = 500;
    return res.end("{}");
  }
  if (req.url === "/fixture/state")
    return res.end(JSON.stringify({ authTokens }));
  if (req.url.startsWith("/fixture/drop")) {
    const user = new URL(req.url, "http://localhost").searchParams.get("user");
    for (const socket of io.sockets.sockets.values()) {
      if (!user || socket.data.userId === user) socket.conn.close();
    }
    return res.end("{}");
  }
  if (req.url.startsWith("/fixture/receipt")) {
    const params = new URL(req.url, "http://localhost").searchParams;
    io.emit("conversation:read", {
      conversationId: "conversation",
      readerId: params.get("reader"),
      lastReadMessageId: params.get("last"),
      readAt: new Date().toISOString(),
    });
    return res.end("{}");
  }
  if (req.url.includes("/messages?")) {
    const url = new URL(req.url, "http://localhost");
    const before = url.searchParams.get("before");
    const limit = Number(url.searchParams.get("limit") || 50);
    const end = before
      ? messages.findIndex((m) => m.id === before)
      : messages.length;
    const start = Math.max(0, end - limit);
    const body = JSON.stringify({
      viewerId,
      items: messages
        .slice(start, end)
        .map((m) => ({ ...m, fromMe: m.senderId === viewerId })),
      hasMore: start > 0,
      nextCursor: start > 0 ? messages[start].id : null,
    });
    const delay = historyDelay;
    historyDelay = 0;
    return setTimeout(() => res.end(body), delay);
  }
  if (req.url.endsWith("/read")) return res.end("{}");
  return res.end(JSON.stringify({ id: "conversation" }));
});
const io = new Server(server);
io.on("connection", (socket) => {
  const token = socket.handshake.auth.token;
  const userId = token.split(":")[0];
  authTokens.push(token);
  socket.data.userId = userId;
  if (token.endsWith(":slow")) {
    setTimeout(() => socket.emit("chat:ready", { userId }), 800);
  } else {
    socket.emit("chat:ready", { userId });
  }
  socket.on("conversation:join", ({ conversationId }) => {
    socket.join(conversationId);
    socket.emit("conversation:joined", { conversationId });
  });
  socket.on("message:send", (payload) => {
    let message = messages.find(
      (m) =>
        m.senderId === userId && m.clientMessageId === payload.clientMessageId,
    );
    if (!message) {
      message = {
        ...payload,
        id: `message-${messages.length + 1}`,
        senderId: userId,
        createdAt: new Date().toISOString(),
      };
      messages.push(message);
    }
    socket.emit("message:sent", {
      clientMessageId: message.clientMessageId,
      messageId: message.id,
      message: { ...message, fromMe: true },
    });
    for (const client of io.sockets.sockets.values()) {
      if (client.rooms.has(message.conversationId))
        client.emit("message:new", {
          ...message,
          fromMe: client.data.userId === message.senderId,
        });
    }
  });
});
server.listen(0, "127.0.0.1", () =>
  process.stdout.write(`${server.address().port}\n`),
);
