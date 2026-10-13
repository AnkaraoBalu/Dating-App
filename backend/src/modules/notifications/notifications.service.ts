import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";
import { FirebasePushSender, type PushMessage } from "./firebase-push.sender";

/** What the app needs to open the right screen when a notification is tapped. */
export type NotificationType = "message" | "match" | "like" | "vibe" | "call";

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

  /** Rings a member whose app is closed or in the background. */
  incomingCall(
    recipientId: string,
    call: { callId: string; callerId: string; conversationId: string },
  ) {
    return this.deliver(recipientId, async () => ({
      title: await this.displayName(call.callerId),
      body: "📞 Incoming voice call",
      data: {
        type: "call",
        callId: call.callId,
        conversationId: call.conversationId,
      },
      group: `call:${call.callId}`,
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

  /** Tells a room's host that someone new joined. */
  vibeRoomJoined(
    hostId: string,
    room: { roomId: string; title: string; joinerId: string },
  ) {
    return this.deliver(hostId, async () => ({
      title: room.title,
      body: `${await this.displayName(room.joinerId)} joined your room 👋`,
      data: { type: "vibe", roomId: room.roomId },
      group: `vibe:${room.roomId}`,
    }));
  }

  /**
   * A message in a Vibe room, for members who don't have it open. One
   * notification per room is kept on screen (it replaces the previous one).
   */
  async vibeRoomMessage(
    recipientIds: string[],
    message: {
      roomId: string;
      title: string;
      senderId: string;
      text: string;
      type?: string;
    },
  ) {
    if (recipientIds.length === 0) return;
    const sender = await this.displayName(message.senderId);
    await Promise.all(
      recipientIds.map((recipientId) =>
        this.deliver(recipientId, async () => ({
          title: message.title,
          body: `${sender}: ${messagePreview(message.type ?? "text", message.text)}`,
          data: { type: "vibe", roomId: message.roomId },
          group: `vibe:${message.roomId}`,
        })),
      ),
    );
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
  if (type === "call") {
    if (text === "missed") return "📞 Missed voice call";
    if (text === "declined") return "📞 Declined voice call";
    return "📞 Voice call";
  }
  const trimmed = text.trim();
  return trimmed.length > 150 ? `${trimmed.slice(0, 147)}…` : trimmed;
}
