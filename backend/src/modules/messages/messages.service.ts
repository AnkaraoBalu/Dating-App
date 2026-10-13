import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";

@Injectable()
export class MessagesService {
  constructor(private readonly prisma: PrismaService) {}

  async userId(clerkUserId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User account was not found.");
    return user.id;
  }

  async openConversation(clerkUserId: string, otherUserId: string) {
    const currentUserId = await this.userId(clerkUserId);
    if (currentUserId === otherUserId) {
      throw new ForbiddenException("You cannot message yourself.");
    }

    const [sentLike, receivedLike] = await Promise.all([
      this.prisma.profileLike.findUnique({
        where: {
          fromUserId_toUserId: {
            fromUserId: currentUserId,
            toUserId: otherUserId,
          },
        },
        select: { id: true },
      }),
      this.prisma.profileLike.findUnique({
        where: {
          fromUserId_toUserId: {
            fromUserId: otherUserId,
            toUserId: currentUserId,
          },
        },
        select: { id: true },
      }),
    ]);
    if (!sentLike || !receivedLike) {
      throw new ForbiddenException("You can message only after matching.");
    }

    const [userOneId, userTwoId] = [currentUserId, otherUserId].sort();
    return this.prisma.conversation.upsert({
      where: { userOneId_userTwoId: { userOneId, userTwoId } },
      create: { userOneId, userTwoId },
      update: {},
      select: { id: true, createdAt: true },
    });
  }

  async markConversationRead(clerkUserId: string, conversationId: string) {
    const userId = await this.userId(clerkUserId);
    const conversation = await this.assertParticipant(userId, conversationId);
    const readAt = new Date();
    return this.prisma.$transaction(async (tx) => {
      // Serialize read resets with the unread increments performed by sends.
      // Otherwise a concurrent new message can lose its unread badge.
      await tx.$queryRaw`SELECT "id" FROM "Conversation" WHERE "id" = ${conversationId} FOR UPDATE`;
      const latestUnreadMessage = await tx.message.findFirst({
        where: {
          conversationId,
          senderId: { not: userId },
          readAt: null,
          createdAt: { lte: readAt },
        },
        select: { id: true },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      });
      if (latestUnreadMessage) {
        await tx.message.updateMany({
          where: {
            conversationId,
            senderId: { not: userId },
            readAt: null,
            createdAt: { lte: readAt },
          },
          data: { readAt },
        });
      }
      const unreadCount = await tx.message.count({
        where: { conversationId, senderId: { not: userId }, readAt: null },
      });
      await tx.conversation.update({
        where: { id: conversationId },
        data:
          conversation.userOneId === userId
            ? { userOneUnreadCount: unreadCount }
            : { userTwoUnreadCount: unreadCount },
      });
      return {
        conversationId,
        readerId: userId,
        readAt: latestUnreadMessage ? readAt.toISOString() : null,
        lastReadMessageId: latestUnreadMessage?.id ?? null,
        unreadCount,
      };
    });
  }

  async setSavedInChat(
    clerkUserId: string,
    conversationId: string,
    messageId: string,
    saved: unknown,
  ) {
    if (typeof saved !== "boolean")
      throw new BadRequestException("Invalid saved state.");
    const userId = await this.userId(clerkUserId);
    await this.assertParticipant(userId, conversationId);
    return this.prisma.$transaction(async (tx) => {
      // Shares the expiry lock: a save either protects content or reports that
      // it has already expired, never revives an expired message.
      await tx.$queryRaw`SELECT "id" FROM "Conversation" WHERE "id" = ${conversationId} FOR UPDATE`;
      const message = await tx.message.findFirst({
        where: { id: messageId, conversationId, type: { not: "expired" } },
      });
      if (!message)
        throw new NotFoundException("Message is no longer available.");
      await tx.message.update({
        where: { id: messageId },
        data: { savedInChat: saved },
      });
      return { conversationId, messageId, savedInChat: saved };
    });
  }

  /** Only the recipient can expire messages they have already read. */
  async expireViewedMessages(
    clerkUserId: string,
    conversationId: string,
    messageIds: unknown,
  ) {
    if (
      !Array.isArray(messageIds) ||
      messageIds.length > 1000 ||
      messageIds.some((id) => typeof id !== "string" || !id || id.length > 100)
    ) {
      throw new BadRequestException("Invalid message IDs.");
    }
    const userId = await this.userId(clerkUserId);
    await this.assertParticipant(userId, conversationId);
    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT "id" FROM "Conversation" WHERE "id" = ${conversationId} FOR UPDATE`;
      const where = {
        conversationId,
        id: { in: messageIds as string[] },
        senderId: { not: userId },
        readAt: { not: null },
        savedInChat: false,
        type: { not: "expired" },
      };
      const rows = await tx.message.findMany({
        where,
        select: { id: true, mediaPublicId: true },
      });
      // Keep only a content-free tombstone so delayed send retries cannot
      // recreate a deleted message and pagination cursors remain valid.
      await tx.message.updateMany({
        where,
        data: {
          type: "expired",
          text: "",
          mediaUrl: null,
          mediaMimeType: null,
          mediaSize: null,
          mediaDurationMs: null,
          latitude: null,
          longitude: null,
        },
      });
      return {
        conversationId,
        messageIds: rows.map((row) => row.id),
        mediaPublicIds: rows.flatMap((row) =>
          row.mediaPublicId ? [row.mediaPublicId] : [],
        ),
      };
    });
  }

  async assertParticipant(userId: string, conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      select: { id: true, userOneId: true, userTwoId: true },
    });
    if (!conversation) throw new NotFoundException("Conversation not found.");
    if (
      conversation.userOneId !== userId &&
      conversation.userTwoId !== userId
    ) {
      throw new ForbiddenException("You are not part of this conversation.");
    }
    return conversation;
  }

  async listMessages(
    clerkUserId: string,
    conversationId: string,
    before?: string,
    requestedLimit = 50,
  ) {
    const userId = await this.userId(clerkUserId);
    await this.assertParticipant(userId, conversationId);
    const limit = Math.min(Math.max(requestedLimit, 1), 100);
    const cursorMessage = before
      ? await this.prisma.message.findFirst({
          where: { id: before, conversationId },
          select: { id: true, createdAt: true },
        })
      : null;
    if (before && !cursorMessage) {
      throw new BadRequestException("Invalid message cursor.");
    }

    const messages = await this.prisma.message.findMany({
      where: {
        conversationId,
        type: { not: "expired" },
        ...(cursorMessage
          ? {
              OR: [
                { createdAt: { lt: cursorMessage.createdAt } },
                {
                  createdAt: cursorMessage.createdAt,
                  id: { lt: cursorMessage.id },
                },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: limit + 1,
    });
    const hasMore = messages.length > limit;
    const page = messages.slice(0, limit).reverse();
    return {
      viewerId: userId,
      expiredIds: (
        await this.prisma.message.findMany({
          where: { conversationId, type: "expired" },
          select: { id: true },
        })
      ).map((message) => message.id),
      items: page.map((message) => ({
        id: message.id,
        clientMessageId: message.clientMessageId,
        conversationId: message.conversationId,
        senderId: message.senderId,
        text: message.text,
        type: message.type,
        mediaUrl: message.mediaUrl,
        mediaPublicId: message.mediaPublicId,
        mediaMimeType: message.mediaMimeType,
        mediaSize: message.mediaSize,
        mediaDurationMs: message.mediaDurationMs,
        latitude: message.latitude,
        longitude: message.longitude,
        savedInChat: message.savedInChat ?? false,
        readAt: message.readAt,
        createdAt: message.createdAt,
        fromMe: message.senderId === userId,
      })),
      hasMore,
      nextCursor: hasMore ? (page[0]?.id ?? null) : null,
    };
  }

  async sendMessage(
    userId: string,
    conversationId: string,
    clientMessageId: string,
    payload: {
      type?: unknown;
      text?: unknown;
      latitude?: unknown;
      longitude?: unknown;
    },
  ) {
    const type = payload.type ?? "text";
    const text = typeof payload.text === "string" ? payload.text.trim() : "";
    if (typeof type !== "string" || !["text", "location"].includes(type)) {
      throw new BadRequestException("Unsupported message type.");
    }
    if (type === "text" && (!text || text.length > 4000)) {
      throw new BadRequestException(
        "Message must be between 1 and 4000 characters.",
      );
    }
    if (type !== "text" && text.length > 4000) {
      throw new BadRequestException("Message caption is too long.");
    }
    if (!clientMessageId || clientMessageId.length > 100) {
      throw new BadRequestException("Invalid client message ID.");
    }
    const conversation = await this.assertParticipant(userId, conversationId);

    const existing = await this.prisma.message.findUnique({
      where: {
        senderId_clientMessageId: { senderId: userId, clientMessageId },
      },
    });
    if (existing) {
      if (existing.conversationId !== conversationId) {
        throw new BadRequestException("Duplicate message ID.");
      }
      return this.messageResponse(existing);
    }

    let latitude: number | undefined;
    let longitude: number | undefined;
    if (type === "location") {
      if (
        typeof payload.latitude !== "number" ||
        typeof payload.longitude !== "number" ||
        !Number.isFinite(payload.latitude) ||
        !Number.isFinite(payload.longitude) ||
        Math.abs(payload.latitude) > 90 ||
        Math.abs(payload.longitude) > 180
      ) {
        throw new BadRequestException("Invalid location coordinates.");
      }
      // Never persist precise device coordinates from a chat location share.
      latitude = Math.round(payload.latitude * 1000) / 1000;
      longitude = Math.round(payload.longitude * 1000) / 1000;
    }

    try {
      const message = await this.prisma.$transaction(async (tx) => {
        const saved = await tx.message.create({
          data: {
            conversationId,
            senderId: userId,
            clientMessageId,
            text,
            type,
            latitude,
            longitude,
          },
        });
        await tx.conversation.update({
          where: { id: conversationId },
          data: {
            updatedAt: new Date(),
            ...(conversation.userOneId === userId
              ? { userTwoUnreadCount: { increment: 1 } }
              : { userOneUnreadCount: { increment: 1 } }),
          },
        });
        return saved;
      });
      return this.messageResponse(message);
    } catch (error) {
      // Two retries can race past the initial duplicate check. A unique-key
      // conflict still confirms the original send, without another increment.
      if (
        error &&
        typeof error === "object" &&
        "code" in error &&
        error.code === "P2002"
      ) {
        const saved = await this.prisma.message.findUnique({
          where: {
            senderId_clientMessageId: { senderId: userId, clientMessageId },
          },
        });
        if (saved?.conversationId === conversationId)
          return this.messageResponse(saved);
      }
      throw error;
    }
  }

  messageResponse(message: {
    id: string;
    clientMessageId: string;
    conversationId: string;
    senderId: string;
    text: string;
    type: string;
    mediaUrl: string | null;
    mediaPublicId: string | null;
    mediaMimeType: string | null;
    mediaSize: number | null;
    mediaDurationMs?: number | null;
    latitude: number | null;
    longitude: number | null;
    savedInChat?: boolean;
    readAt: Date | null;
    createdAt: Date;
  }) {
    return {
      id: message.id,
      clientMessageId: message.clientMessageId,
      conversationId: message.conversationId,
      senderId: message.senderId,
      text: message.text,
      type: message.type,
      mediaUrl: message.mediaUrl,
      mediaPublicId: message.mediaPublicId,
      mediaMimeType: message.mediaMimeType,
      mediaSize: message.mediaSize,
      mediaDurationMs: message.mediaDurationMs ?? null,
      latitude: message.latitude,
      longitude: message.longitude,
      savedInChat: message.savedInChat ?? false,
      readAt: message.readAt,
      createdAt: message.createdAt,
    };
  }
}
