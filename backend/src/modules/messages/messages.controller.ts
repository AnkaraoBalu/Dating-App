import {
  Logger,
  Controller,
  Body,
  UploadedFile,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Req,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ClerkAuthGuard, type ClerkRequest } from "../auth/clerk-auth.guard";
import { MessageMediaService } from "./message-media.service";
import { ConversationsService } from "./conversations.service";
import { MessagesService } from "./messages.service";
import { MessagesGateway } from "./messages.gateway";
import { SendRateLimiter } from "../rate-limit/send-rate-limiter.service";
import { VOICE_NOTE_MAX_BYTES } from "./voice-note.storage";

@Controller("messages")
@UseGuards(ClerkAuthGuard)
export class MessagesController {
  /** Viewed messages disappear this long after the recipient leaves the chat. */
  static expiryDelayMs = 60_000;

  private readonly logger = new Logger(MessagesController.name);
  // Keyed by "<clerk user>:<conversation>". Timers live in memory: if the
  // server restarts inside the minute, those messages stay until the next
  // leave, which is the safe direction to fail.
  private readonly pendingExpiry = new Map<
    string,
    { timer: NodeJS.Timeout; messageIds: Set<string> }
  >();

  constructor(
    private readonly messages: MessagesService,
    private readonly conversations: ConversationsService,
    private readonly media: MessageMediaService,
    private readonly gateway: MessagesGateway,
    private readonly limiter: SendRateLimiter,
  ) {}

  @Post("conversations/:conversationId/images")
  @UseInterceptors(
    FileInterceptor("file", {
      limits: { fileSize: 10 * 1024 * 1024, files: 1 },
    }),
  )
  async sendImage(
    @Req() request: ClerkRequest,
    @Param("conversationId") conversationId: string,
    @Body("clientMessageId") clientMessageId: string,
    @Body("caption") caption: string | undefined,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    // Photos share the chat allowance with text sent over the socket.
    const userId = await this.messages.userId(request.auth.userId);
    this.limiter.consume(`chat:${userId}`);
    const message = await this.media.sendImage(
      request.auth.userId,
      conversationId,
      clientMessageId,
      caption ?? "",
      file,
    );
    // Upload persistence is successful even if live fan-out is temporarily
    // unavailable; recipients recover it from history on reconnect.
    await this.gateway
      .broadcastMessage(conversationId, message)
      .catch(() => undefined);
    await this.gateway.announceNewMessage(conversationId, message);
    return { ...message, fromMe: true };
  }

  @Post("conversations/:conversationId/voice")
  @UseInterceptors(
    FileInterceptor("file", {
      limits: { fileSize: VOICE_NOTE_MAX_BYTES, files: 1 },
    }),
  )
  async sendVoice(
    @Req() request: ClerkRequest,
    @Param("conversationId") conversationId: string,
    @Body("clientMessageId") clientMessageId: string,
    @Body("durationMs") durationMs: string | undefined,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const userId = await this.messages.userId(request.auth.userId);
    this.limiter.consume(`chat:${userId}`);
    const message = await this.media.sendVoice(
      request.auth.userId,
      conversationId,
      clientMessageId,
      durationMs,
      file,
    );
    await this.gateway
      .broadcastMessage(conversationId, message)
      .catch(() => undefined);
    await this.gateway.announceNewMessage(conversationId, message);
    return { ...message, fromMe: true };
  }

  @Post("conversations/:otherUserId")
  openConversation(
    @Req() request: ClerkRequest,
    @Param("otherUserId") otherUserId: string,
  ) {
    return this.messages.openConversation(request.auth.userId, otherUserId);
  }

  @Get("conversations")
  listConversations(
    @Req() request: ClerkRequest,
    @Query("search") search?: string,
  ) {
    return this.conversations.listConversations(request.auth.userId, search);
  }

  @Post("conversations/:conversationId/read")
  markConversationRead(
    @Req() request: ClerkRequest,
    @Param("conversationId") conversationId: string,
  ) {
    this.cancelPendingExpiry(request.auth.userId, conversationId);
    return this.messages
      .markConversationRead(request.auth.userId, conversationId)
      .then((receipt) => {
        if (receipt.lastReadMessageId && receipt.readAt) {
          this.gateway.broadcastRead(conversationId, receipt);
        }
        // Unread badges on the reader's other screens and devices.
        void this.gateway.notifyInboxChanged(conversationId);
        return receipt;
      });
  }

  @Post("conversations/:conversationId/messages/:messageId/saved")
  async saveMessage(
    @Req() request: ClerkRequest,
    @Param("conversationId") conversationId: string,
    @Param("messageId") messageId: string,
    @Body("savedInChat") saved: unknown,
  ) {
    const result = await this.messages.setSavedInChat(
      request.auth.userId,
      conversationId,
      messageId,
      saved,
    );
    this.gateway.broadcastSaved(conversationId, result);
    return result;
  }

  /**
   * The recipient left the chat (or backgrounded the app). Their viewed
   * messages disappear after [expiryDelayMs] unless they come back first.
   */
  @Post("conversations/:conversationId/leave")
  async leaveConversation(
    @Req() request: ClerkRequest,
    @Param("conversationId") conversationId: string,
    @Body("messageIds") messageIds: unknown,
  ) {
    const clerkUserId = request.auth.userId;
    const ids = await this.messages.validateLeave(
      clerkUserId,
      conversationId,
      messageIds,
    );
    const key = `${clerkUserId}:${conversationId}`;
    const pending = this.pendingExpiry.get(key);
    if (pending) clearTimeout(pending.timer);
    const all = new Set([...(pending?.messageIds ?? []), ...ids]);
    const timer = setTimeout(() => {
      this.pendingExpiry.delete(key);
      void this.expireNow(clerkUserId, conversationId, [...all]);
    }, MessagesController.expiryDelayMs);
    timer.unref?.();
    this.pendingExpiry.set(key, { timer, messageIds: all });
    return {
      conversationId,
      messageIds: [],
      expiresInMs: MessagesController.expiryDelayMs,
    };
  }

  /** Coming back to the chat keeps its messages until the next leave. */
  private cancelPendingExpiry(clerkUserId: string, conversationId: string) {
    const key = `${clerkUserId}:${conversationId}`;
    const pending = this.pendingExpiry.get(key);
    if (!pending) return;
    clearTimeout(pending.timer);
    this.pendingExpiry.delete(key);
  }

  private async expireNow(
    clerkUserId: string,
    conversationId: string,
    messageIds: string[],
  ) {
    try {
      const expired = await this.messages.expireViewedMessages(
        clerkUserId,
        conversationId,
        messageIds,
      );
      if (expired.messageIds.length) {
        this.gateway.broadcastExpired(conversationId, {
          conversationId,
          messageIds: expired.messageIds,
        });
        void this.gateway.notifyInboxChanged(conversationId);
      }
      await this.media.deleteExpiredMedia(expired.mediaPublicIds);
    } catch (error) {
      this.logger.error("Could not expire viewed messages", error);
    }
  }

  @Get("conversations/:conversationId/messages")
  listMessages(
    @Req() request: ClerkRequest,
    @Param("conversationId") conversationId: string,
    @Query("before") before?: string,
    @Query("limit", new ParseIntPipe({ optional: true })) limit = 50,
  ) {
    // Opening the chat (its newest page) cancels a pending expiry.
    if (before == null) {
      this.cancelPendingExpiry(request.auth.userId, conversationId);
    }
    return this.messages.listMessages(
      request.auth.userId,
      conversationId,
      before,
      limit,
    );
  }
}
