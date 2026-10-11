import { Injectable, Logger } from "@nestjs/common";
import type { Server } from "socket.io";

/**
 * Events pushed to a user's private room so every open app session can refresh
 * without polling. Payloads only name what changed; clients reload the details
 * over REST, which keeps per-viewer data (unread counts, names) authoritative.
 */
export type RealtimeEvent = "inbox:changed" | "like:new" | "match:new";

@Injectable()
export class RealtimeService {
  private readonly logger = new Logger(RealtimeService.name);
  private server?: Server;

  /** Called once by the Socket.IO gateway when the server starts. */
  attach(server: Server) {
    this.server = server;
  }

  static userRoom(userId: string) {
    return `user:${userId}`;
  }

  /** Best effort: a delivery failure never fails the request that caused it. */
  notifyUser(userId: string, event: RealtimeEvent, payload: object = {}) {
    try {
      this.server?.to(RealtimeService.userRoom(userId)).emit(event, payload);
    } catch (error) {
      this.logger.error(`Could not deliver ${event}`, error);
    }
  }
}
