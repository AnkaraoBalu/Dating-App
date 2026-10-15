import { ConfigService } from "@nestjs/config";
import { Logger } from "@nestjs/common";
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from "@nestjs/websockets";
import { verifyToken } from "@clerk/backend";
import { Server, Socket } from "socket.io";
import { PrismaService } from "../../database/prisma.service";
import { MessagesService } from "./messages.service";
import {
  demoAuthSecret,
  verifyDemoSessionToken,
} from "../demo-auth/demo-session";
import { RealtimeService } from "../realtime/realtime.service";
import { NotificationsService } from "../notifications/notifications.service";
import {
  SendRateLimiter,
  TooManyMessagesException,
} from "../rate-limit/send-rate-limiter.service";

type EventPayload = Record<string, unknown>;

@WebSocketGateway({ maxHttpBufferSize: 64 * 1024 })
// The app's single Socket.IO gateway: chat rooms per conversation, plus a
// private room per user for inbox, like and match events (RealtimeService).
export class MessagesGateway
  implements OnGatewayInit<Server>, OnGatewayConnection<Socket>
{
  private readonly logger = new Logger(MessagesGateway.name);
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly messages: MessagesService,
    private readonly realtime?: RealtimeService,
    private readonly limiter?: SendRateLimiter,
    private readonly notifications?: NotificationsService,
  ) {}

  afterInit(server: Server) {
    this.realtime?.attach(server);
  }

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token;
      if (typeof token !== "string" || token.trim().length === 0) {
        throw new Error("Missing bearer token");
      }
      const demoSecret = demoAuthSecret(this.config);
      const demoUserId = demoSecret
        ? verifyDemoSessionToken(token, demoSecret)
        : null;
      const clerkUserId =
        demoUserId ??
        (
          await verifyToken(token, {
            secretKey: this.config.getOrThrow<string>("CLERK_SECRET_KEY"),
          })
        ).sub;
      if (!clerkUserId) throw new Error("Invalid session token");
      const user = await this.prisma.user.findUnique({
        where: { clerkUserId },
        select: { id: true },
      });
      if (!user) throw new Error("User account not found");
      client.data.userId = user.id;
      await client.join(RealtimeService.userRoom(user.id));
      // Share the authenticated database user ID with this socket so the app
      // can classify its own messages without guessing from the peer ID.
      client.emit("chat:ready", { userId: user.id });
    } catch {
      client.disconnect(true);
    }
  }

  @SubscribeMessage("conversation:join")
  async joinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: EventPayload,
  ) {
    const userId = this.authenticatedUserId(client);
    const conversationId = payload?.conversationId;
    if (!userId || typeof conversationId !== "string") return;
    try {
      await this.messages.assertParticipant(userId, conversationId);
      await client.join(this.room(conversationId));
      client.emit("conversation:joined", { conversationId });
    } catch {
      client.emit("chat:error", { message: "Conversation access denied." });
    }
  }

  /**
   * The app reports when its open chat goes to the background (`active:
   * false`) and comes back, so pushes still reach a member who left a chat
   * open on a locked phone.
   */
  @SubscribeMessage("conversation:presence")
  presence(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: EventPayload,
  ) {
    client.data.away = payload?.active === false;
  }

  @SubscribeMessage("message:send")
  async sendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: EventPayload,
  ) {
    const userId = this.authenticatedUserId(client);
    const { conversationId, clientMessageId } = payload ?? {};
    if (
      !userId ||
      typeof conversationId !== "string" ||
      typeof clientMessageId !== "string"
    ) {
      client.emit("message:error", {
        clientMessageId,
        message: "Invalid message payload.",
      });
      return;
    }

    try {
      this.limiter?.consume(`chat:${userId}`);
      const message = await this.messages.sendMessage(
        userId,
        conversationId,
        clientMessageId,
        payload,
      );
      client.emit("message:sent", {
        clientMessageId,
        messageId: message.id,
        message: { ...message, fromMe: true },
      });
      // Persistence is confirmed independently of room fan-out. A broadcast
      // failure must not tell the sender that a saved message failed to send.
      try {
        await this.broadcastMessage(conversationId, message);
      } catch (error) {
        this.logger.error("Saved message could not be broadcast", error);
      }
      await this.announceNewMessage(conversationId, message);
    } catch (error) {
      client.emit(
        "message:error",
        error instanceof TooManyMessagesException
          ? {
              clientMessageId,
              message: error.message,
              retryAfterSeconds: error.retryAfterSeconds,
            }
          : { clientMessageId, message: "Could not send message. Try again." },
      );
    }
  }

  async broadcastMessage(
    conversationId: string,
    message: { senderId: string; [key: string]: unknown },
  ) {
    // `fromMe` is viewer-specific. Send each room participant a copy based on
    // the authenticated identity attached to their socket.
    const sockets = await this.server
      .in(this.room(conversationId))
      .fetchSockets();
    for (const socket of sockets) {
      socket.emit("message:new", {
        ...message,
        fromMe: message.senderId === socket.data.userId,
      });
    }
  }

  /**
   * Tells both participants' other screens (chat list, unread badges) that a
   * conversation changed, including users who don't have it open.
   */
  /**
   * After a message is saved: refresh both members' inboxes, and push it to
   * the recipient unless they are looking at this conversation right now.
   */
  async announceNewMessage(
    conversationId: string,
    message: { senderId: string; type?: unknown; text?: unknown },
  ) {
    if (message.type === "expired") return;
    await this.notifyInboxChanged(conversationId);
    if (!this.notifications) return;
    try {
      const conversation = await this.prisma.conversation.findUnique({
        where: { id: conversationId },
        select: { userOneId: true, userTwoId: true },
      });
      if (!conversation) return;
      const recipientId =
        conversation.userOneId === message.senderId
          ? conversation.userTwoId
          : conversation.userOneId;
      if (await this.isViewing(recipientId, conversationId)) return;
      void this.notifications.newMessage(recipientId, {
        senderId: message.senderId,
        conversationId,
        type: typeof message.type === "string" ? message.type : "text",
        text: typeof message.text === "string" ? message.text : "",
      });
    } catch (error) {
      this.logger.error("Message push could not be prepared", error);
    }
  }

  private async isViewing(userId: string, conversationId: string) {
    const sockets = await this.server
      .in(this.room(conversationId))
      .fetchSockets();
    return sockets.some(
      (socket) => socket.data.userId === userId && socket.data.away !== true,
    );
  }

  async notifyInboxChanged(conversationId: string) {
    try {
      const conversation = await this.prisma.conversation.findUnique({
        where: { id: conversationId },
        select: { userOneId: true, userTwoId: true },
      });
      if (!conversation || !this.realtime) return;
      for (const userId of [conversation.userOneId, conversation.userTwoId]) {
        this.realtime.notifyUser(userId, "inbox:changed", { conversationId });
      }
    } catch (error) {
      this.logger.error("Inbox change could not be announced", error);
    }
  }

  broadcastSaved(conversationId: string, payload: unknown) {
    this.server.to(this.room(conversationId)).emit("message:saved", payload);
  }

  broadcastExpired(conversationId: string, payload: unknown) {
    this.server.to(this.room(conversationId)).emit("messages:expired", payload);
  }

  broadcastRead(conversationId: string, receipt: unknown) {
    this.server
      .to(this.room(conversationId))
      .emit("conversation:read", receipt);
  }

  private authenticatedUserId(client: Socket): string | undefined {
    const userId = client.data.userId;
    return typeof userId === "string" ? userId : undefined;
  }

  private room(conversationId: string) {
    return `conversation:${conversationId}`;
  }
}
