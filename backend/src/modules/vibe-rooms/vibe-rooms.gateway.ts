import { Logger } from "@nestjs/common";
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from "@nestjs/websockets";
import { Server, Socket } from "socket.io";
import { RealtimeService } from "../realtime/realtime.service";
import { VibeRoomMessagesService } from "./vibe-room-messages.service";

type EventPayload = Record<string, unknown>;

/**
 * Live Vibe room chat. Sockets are authenticated by MessagesGateway on
 * connect (`client.data.userId`); this gateway only adds room membership.
 * Messages are still sent over REST, then pushed here to everyone in the room.
 */
@WebSocketGateway({ maxHttpBufferSize: 64 * 1024 })
export class VibeRoomsGateway {
  private readonly logger = new Logger(VibeRoomsGateway.name);
  @WebSocketServer()
  server!: Server;

  constructor(private readonly messages: VibeRoomMessagesService) {}

  static room(roomId: string) {
    return `vibe:${roomId}`;
  }

  @SubscribeMessage("vibe:join")
  async join(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: EventPayload,
  ) {
    const userId = client.data.userId;
    const roomId = payload?.roomId;
    if (typeof userId !== "string" || typeof roomId !== "string") return;
    try {
      await this.messages.assertMember(userId, roomId);
      await client.join(VibeRoomsGateway.room(roomId));
      client.emit("vibe:joined", { roomId });
    } catch {
      client.emit("vibe:error", {
        roomId,
        message: "Join this room before viewing its chat.",
      });
    }
  }

  @SubscribeMessage("vibe:leave")
  async leave(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: EventPayload,
  ) {
    const roomId = payload?.roomId;
    if (typeof roomId === "string") {
      await client.leave(VibeRoomsGateway.room(roomId));
    }
  }

  /** Best effort: the message is already saved and returned to the sender. */
  async broadcastMessage(
    roomId: string,
    message: { senderId: string; [key: string]: unknown },
  ) {
    try {
      const sockets = await this.server
        .in(VibeRoomsGateway.room(roomId))
        .fetchSockets();
      for (const socket of sockets) {
        // `isMe` is viewer-specific, so each socket gets its own copy.
        socket.emit("vibe:message", {
          ...message,
          roomId,
          isMe: message.senderId === socket.data.userId,
        });
      }
    } catch (error) {
      this.logger.error("Vibe room message could not be broadcast", error);
    }
  }

  /** After leaving over REST, stop live delivery to all of the user's sockets. */
  removeMember(roomId: string, userId: string) {
    try {
      this.server
        .in(RealtimeService.userRoom(userId))
        .socketsLeave(VibeRoomsGateway.room(roomId));
    } catch (error) {
      this.logger.error("Could not remove member from live room", error);
    }
  }
}
