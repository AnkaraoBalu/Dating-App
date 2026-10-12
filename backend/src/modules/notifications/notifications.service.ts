import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";
import { FirebasePushSender, type PushMessage } from "./firebase-push.sender";

/** What the app needs to open the right screen when a notification is tapped. */
export type NotificationType = "message" | "match" | "like";

/**
 * Every push notification the app sends goes through here: registering
 * phones, choosing the text for each notification type, and sending.
 * Sending is best effort and never throws into the request that caused it.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly sender: FirebasePushSender,
  ) {}

  async registerDevice(
    clerkUserId: string,
    token: string,
    platform: "android" | "ios",
  ) {
    const userId = await this.userId(clerkUserId);
    // A phone's token moves to whoever signed in on it most recently.
    await this.prisma.pushDevice.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId, platform, lastSeenAt: new Date() },
    });
    return { registered: true };
  }

  async removeDevice(clerkUserId: string, token: string) {
    const userId = await this.userId(clerkUserId);
    await this.prisma.pushDevice.deleteMany({ where: { token, userId } });
    return { removed: true };
  }

  newMessage(
    recipientId: string,
    message: {
      senderId: string;
      conversationId: string;
      type: string;
      text: string;
    },
  ) {
    return this.deliver(recipientId, async () => ({
      title: await this.displayName(message.senderId),
      body: messagePreview(message.type, message.text),
      data: { type: "message", conversationId: message.conversationId },
      group: `conversation:${message.conversationId}`,
    }));
  }

  newMatch(recipientId: string, otherUserId: string) {
    return this.deliver(recipientId, async () => ({
      title: "It's a match! 🎉",
      body: `You and ${await this.displayName(otherUserId)} liked each other. Say hi!`,
      data: { type: "match", userId: otherUserId },
    }));
  }

  /** Doesn't name the liker: likes are only revealed in the app. */
  newLike(recipientId: string) {
    return this.deliver(recipientId, async () => ({
      title: "Someone likes you 💘",
      body: "Open Matchify to see who.",
      data: { type: "like" },
    }));
  }

  private async deliver(
    userId: string,
    build: () => Promise<PushMessage & { data: { type: NotificationType } }>,
  ) {
    try {
      const devices = await this.prisma.pushDevice.findMany({
        where: { userId },
        select: { token: true },
      });
      if (devices.length === 0) return;
      const dead = await this.sender.send(
        devices.map((device) => device.token),
        await build(),
      );
      if (dead.length > 0) {
        await this.prisma.pushDevice.deleteMany({
          where: { token: { in: dead } },
        });
      }
    } catch (error) {
      this.logger.error("Push notification failed", error);
    }
  }

  private async displayName(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { username: true, firstName: true },
    });
    return user?.username?.trim() || user?.firstName?.trim() || "Someone";
  }

  private async userId(clerkUserId: string) {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User account was not found.");
    return user.id;
  }
}

export function messagePreview(type: string, text: string) {
  if (type === "image") return text.trim() ? `📷 ${text.trim()}` : "📷 Photo";
  if (type === "location") return "📍 Shared a location";
  if (type === "voice") return "🎤 Voice message";
  const trimmed = text.trim();
  return trimmed.length > 150 ? `${trimmed.slice(0, 147)}…` : trimmed;
}
