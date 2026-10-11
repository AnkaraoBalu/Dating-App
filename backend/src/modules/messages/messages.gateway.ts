import { ConfigService } from "@nestjs/config";
import { Logger } from "@nestjs/common";
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from "@nestjs/websockets";
import { verifyToken } from "@clerk/backend";
import { Server, Socket } from "socket.io";
import { PrismaService } from "../../database/prisma.service";
import { MessagesService } from "./messages.service";
import { verifyDemoSessionToken } from "../demo-auth/demo-session";

type EventPayload = Record<string, unknown>;

@WebSocketGateway({ maxHttpBufferSize: 64 * 1024 })
export class MessagesGateway implements OnGatewayConnection<Socket> {
  private readonly logger = new Logger(MessagesGateway.name);
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly messages: MessagesService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token;
      if (typeof token !== "string" || token.trim().length === 0) {
        throw new Error("Missing bearer token");
      }
      const demoSecret = this.config.get<string>("DEMO_AUTH_SECRET");
      const demoUserId =
        this.config.get<string>("NODE_ENV") !== "production" &&
        this.config.get<string>("DEMO_AUTH_ENABLED") === "true" &&
        demoSecret
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
    } catch {
      client.emit("message:error", {
        clientMessageId,
        message: "Could not send message. Try again.",
      });
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
