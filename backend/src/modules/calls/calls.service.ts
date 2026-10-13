import {
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  ServiceUnavailableException,
} from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../../database/prisma.service";
import { LiveKitService } from "../livekit/livekit.service";
import { MessagesGateway } from "../messages/messages.gateway";
import { MessagesService } from "../messages/messages.service";
import { NotificationsService } from "../notifications/notifications.service";
import { RealtimeService } from "../realtime/realtime.service";

/** How long a call rings before it counts as missed. */
export const RING_TIMEOUT_MS = 30_000;
const ACTIVE = ["ringing", "accepted"];
const fallbackAvatar = "assets/images/boys-images/golden_hour_white_shirt.png";

const callRelations = {
  caller: { select: personSelect() },
  callee: { select: personSelect() },
} satisfies Prisma.CallInclude;

type CallWithPeople = Prisma.CallGetPayload<{ include: typeof callRelations }>;
type Person = CallWithPeople["caller"];

/**
 * One-to-one voice calls between matched members. The call itself is a
 * two-person LiveKit room; this service rings the callee (live event plus
 * push), tracks ringing → accepted → ended, and leaves a line in the chat.
 */
@Injectable()
export class CallsService implements OnModuleDestroy {
  private readonly logger = new Logger(CallsService.name);
  private readonly ringTimers = new Map<string, NodeJS.Timeout>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly liveKit: LiveKitService,
    private readonly messages: MessagesService,
    private readonly gateway: MessagesGateway,
    private readonly realtime: RealtimeService,
    private readonly notifications: NotificationsService,
  ) {}

  onModuleDestroy() {
    for (const timer of this.ringTimers.values()) clearTimeout(timer);
  }

  async start(clerkUserId: string, conversationId: string) {
    const userId = await this.messages.userId(clerkUserId);
    const conversation = await this.messages.assertParticipant(
      userId,
      conversationId,
    );
    if (!this.liveKit.configured) {
      throw new ServiceUnavailableException("Voice is not configured yet.");
    }
    const calleeId =
      conversation.userOneId === userId
        ? conversation.userTwoId
        : conversation.userOneId;

    await this.clearStaleCalls([userId, calleeId]);
    if (await this.activeCall(userId)) {
      throw new ConflictException("You are already on a call.");
    }
    if (await this.activeCall(calleeId)) {
      throw new ConflictException("They are on another call right now.");
    }

    const call = await this.prisma.call.create({
      data: { conversationId, callerId: userId, calleeId },
      include: callRelations,
    });
    this.ringTimers.set(
      call.id,
      setTimeout(() => void this.finish(call.id, "missed"), RING_TIMEOUT_MS),
    );
    this.realtime.notifyUser(calleeId, "call:incoming", { callId: call.id });
    void this.notifications.incomingCall(calleeId, {
      callId: call.id,
      callerId: userId,
      conversationId,
    });
    return this.withJoin(call, userId);
  }

  async get(clerkUserId: string, callId: string) {
    const userId = await this.messages.userId(clerkUserId);
    const call = await this.participantCall(userId, callId);
    await this.clearStaleCalls([call.callerId, call.calleeId]);
    return this.view(await this.load(callId), userId);
  }

  async accept(clerkUserId: string, callId: string) {
    const userId = await this.messages.userId(clerkUserId);
    const call = await this.participantCall(userId, callId);
    if (call.calleeId !== userId) {
      throw new ForbiddenException("Only the person being called can answer.");
    }
    const answered = await this.prisma.call.updateMany({
      where: { id: callId, status: "ringing" },
      data: { status: "accepted", answeredAt: new Date() },
    });
    if (answered.count === 0) {
      throw new ConflictException("This call has already ended.");
    }
    this.clearRingTimer(callId);
    this.announce(call, "accepted");
    return this.withJoin(await this.load(callId), userId);
  }

  async decline(clerkUserId: string, callId: string) {
    const userId = await this.messages.userId(clerkUserId);
    const call = await this.participantCall(userId, callId);
    if (call.calleeId !== userId) {
      throw new ForbiddenException("Only the person being called can decline.");
    }
    await this.finish(callId, "declined");
    return this.view(await this.load(callId), userId);
  }

  /** Hang up: cancels a call still ringing, or ends a connected one. */
  async end(clerkUserId: string, callId: string) {
    const userId = await this.messages.userId(clerkUserId);
    const call = await this.participantCall(userId, callId);
    if (call.status === "ringing") {
      await this.finish(
        callId,
        call.callerId === userId ? "cancelled" : "declined",
      );
    } else if (call.status === "accepted") {
      await this.finish(callId, "ended");
    }
    return this.view(await this.load(callId), userId);
  }

  /**
   * Moves an active call to a final status exactly once, then tells both
   * members, closes the audio room and records the call in the chat.
   */
  async finish(callId: string, status: string) {
    this.clearRingTimer(callId);
    const endedAt = new Date();
    const updated = await this.prisma.call.updateMany({
      where: { id: callId, status: { in: ACTIVE } },
      data: { status, endedAt },
    });
    if (updated.count === 0) return;
    const call = await this.load(callId);
    this.announce(call, status);
    void this.liveKit.deleteRoom(callRoom(callId));
    await this.recordInChat(call).catch((error) =>
      this.logger.error(`Call ${callId} could not be added to the chat`, error),
    );
  }

  private async recordInChat(call: CallWithPeople) {
    const outcome =
      call.status === "ended"
        ? "completed"
        : call.status === "declined"
          ? "declined"
          : "missed";
    const durationMs =
      call.answeredAt && call.endedAt
        ? call.endedAt.getTime() - call.answeredAt.getTime()
        : null;
    const message = await this.prisma.$transaction(async (tx) => {
      const saved = await tx.message.create({
        data: {
          conversationId: call.conversationId,
          senderId: call.callerId,
          clientMessageId: `call:${call.id}`,
          text: outcome,
          type: "call",
          mediaDurationMs: durationMs,
        },
      });
      if (outcome === "missed") {
        const conversation = await tx.conversation.findUniqueOrThrow({
          where: { id: call.conversationId },
          select: { userOneId: true },
        });
        await tx.conversation.update({
          where: { id: call.conversationId },
          data:
            conversation.userOneId === call.calleeId
              ? { userOneUnreadCount: { increment: 1 } }
              : { userTwoUnreadCount: { increment: 1 } },
        });
      }
      return saved;
    });
    const response = this.messages.messageResponse(message);
    await this.gateway
      .broadcastMessage(call.conversationId, response)
      .catch(() => undefined);
    if (outcome === "missed") {
      // Pushes "Missed voice call" unless they have the chat open.
      await this.gateway.announceNewMessage(call.conversationId, response);
    } else {
      await this.gateway.notifyInboxChanged(call.conversationId);
    }
  }

  /**
   * Finishes calls left behind by a restart or a crashed app: ringing past
   * its timeout, or connected with nobody left in the audio room.
   */
  private async clearStaleCalls(userIds: string[]) {
    const calls = await this.prisma.call.findMany({
      where: {
        status: { in: ACTIVE },
        OR: [{ callerId: { in: userIds } }, { calleeId: { in: userIds } }],
      },
      select: { id: true, status: true, createdAt: true, answeredAt: true },
    });
    const now = Date.now();
    for (const call of calls) {
      if (call.status === "ringing") {
        if (now - call.createdAt.getTime() > RING_TIMEOUT_MS + 15_000) {
          await this.finish(call.id, "missed");
        }
        continue;
      }
      const answeredAgo = now - (call.answeredAt?.getTime() ?? now);
      if (answeredAgo < 60_000) continue;
      if ((await this.liveKit.participantCount(callRoom(call.id))) === 0) {
        await this.finish(call.id, "ended");
      }
    }
  }

  private activeCall(userId: string) {
    return this.prisma.call.findFirst({
      where: {
        status: { in: ACTIVE },
        OR: [{ callerId: userId }, { calleeId: userId }],
      },
      select: { id: true },
    });
  }

  private async participantCall(userId: string, callId: string) {
    const call = await this.prisma.call.findUnique({ where: { id: callId } });
    if (!call) throw new NotFoundException("Call not found.");
    if (call.callerId !== userId && call.calleeId !== userId) {
      throw new ForbiddenException("You are not part of this call.");
    }
    return call;
  }

  private load(callId: string) {
    return this.prisma.call.findUniqueOrThrow({
      where: { id: callId },
      include: callRelations,
    });
  }

  private announce(
    call: { id: string; callerId: string; calleeId: string },
    status: string,
  ) {
    for (const userId of [call.callerId, call.calleeId]) {
      this.realtime.notifyUser(userId, "call:updated", {
        callId: call.id,
        status,
      });
    }
  }

  private clearRingTimer(callId: string) {
    clearTimeout(this.ringTimers.get(callId));
    this.ringTimers.delete(callId);
  }

  private async withJoin(call: CallWithPeople, viewerId: string) {
    const me = call.callerId === viewerId ? call.caller : call.callee;
    const join = await this.liveKit.joinToken({
      room: callRoom(call.id),
      identity: viewerId,
      name: displayName(me),
    });
    return { ...this.view(call, viewerId), ...join };
  }

  private view(call: CallWithPeople, viewerId: string) {
    const isCaller = call.callerId === viewerId;
    const peer = isCaller ? call.callee : call.caller;
    return {
      id: call.id,
      conversationId: call.conversationId,
      status: call.status,
      isCaller,
      peer: {
        id: peer.id,
        name: displayName(peer),
        avatar: avatarOf(peer),
      },
      createdAt: call.createdAt.toISOString(),
      answeredAt: call.answeredAt?.toISOString() ?? null,
      endedAt: call.endedAt?.toISOString() ?? null,
    };
  }
}

export function callRoom(callId: string) {
  return `call-${callId}`;
}

function personSelect() {
  return {
    id: true,
    username: true,
    firstName: true,
    lastName: true,
    imageUrl: true,
    profile: {
      select: {
        photos: {
          orderBy: { position: "asc" as const },
          take: 1,
          select: { secureUrl: true },
        },
      },
    },
  };
}

function displayName(person: Person) {
  return (
    [person.firstName, person.lastName]
      .filter((part): part is string => Boolean(part?.trim()))
      .join(" ") ||
    person.username ||
    "Member"
  );
}

function avatarOf(person: Person) {
  return (
    person.profile?.photos[0]?.secureUrl ?? person.imageUrl ?? fallbackAvatar
  );
}
