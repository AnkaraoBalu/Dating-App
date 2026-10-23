import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../../database/prisma.service";
import {
  CreateVibeRoomDto,
  ListVibeRoomsQueryDto,
  UpdateVibeRoomDto,
} from "./dto/vibe-room.dto";

const fallbackAvatar = "assets/images/boys-images/golden_hour_white_shirt.png";

function roomRelations(viewerId: string) {
  return {
    host: {
      select: {
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
      },
    },
    saves: { where: { userId: viewerId }, select: { userId: true } },
    members: {
      where: { leftAt: null },
      orderBy: { joinedAt: "asc" as const },
      take: 20,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            firstName: true,
            lastName: true,
            imageUrl: true,
            lastActiveAt: true,
            profile: {
              select: {
                bio: true,
                photos: {
                  orderBy: { position: "asc" as const },
                  take: 1,
                  select: { secureUrl: true },
                },
              },
            },
            onboardingProfile: {
              select: { birthDate: true, interests: true },
            },
          },
        },
      },
    },
  } satisfies Prisma.VibeRoomInclude;
}

type RoomWithRelations = Prisma.VibeRoomGetPayload<{
  include: ReturnType<typeof roomRelations>;
}>;

@Injectable()
export class VibeRoomsService {
  constructor(private readonly prisma: PrismaService) {}

  private async databaseUserId(clerkUserId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) {
      throw new NotFoundException("User not synced yet. Open /users/me first.");
    }
    return user.id;
  }

  async list(clerkUserId: string, query: ListVibeRoomsQueryDto) {
    const userId = await this.databaseUserId(clerkUserId);
    const search = query.search?.trim();
    const rooms = await this.prisma.vibeRoom.findMany({
      where: {
        AND: [
          ...(query.categoryId ? [{ categoryId: query.categoryId }] : []),
          ...(search
            ? [
                {
                  OR: [
                    {
                      title: { contains: search, mode: "insensitive" as const },
                    },
                    {
                      description: {
                        contains: search,
                        mode: "insensitive" as const,
                      },
                    },
                  ],
                },
              ]
            : []),
          {
            OR: [
              { inviteOnly: false },
              { hostUserId: userId },
              { members: { some: { userId, leftAt: null } } },
            ],
          },
        ],
      },
      include: roomRelations(userId),
      orderBy: [
        { isLive: "desc" },
        { participantCount: "desc" },
        { createdAt: "desc" },
      ],
    });
    const memberships = rooms.length
      ? await this.prisma.vibeRoomMember.findMany({
          where: {
            roomId: { in: rooms.map((room) => room.id) },
            userId,
            leftAt: null,
          },
          select: { roomId: true },
        })
      : [];
    const joinedRoomIds = new Set(
      memberships.map((membership) => membership.roomId),
    );
    return rooms.map((room) =>
      this.serializeRoom(room, userId, joinedRoomIds.has(room.id)),
    );
  }

  async create(clerkUserId: string, dto: CreateVibeRoomDto) {
    const hostUserId = await this.databaseUserId(clerkUserId);
    const host = await this.prisma.user.findUnique({
      where: { id: hostUserId },
      select: { profile: { select: { location: true } } },
    });

    return this.prisma.$transaction(async (tx) => {
      const room = await tx.vibeRoom.create({
        data: {
          title: dto.title.trim(),
          description: dto.description.trim(),
          categoryId: dto.categoryId,
          emoji: dto.emoji,
          coverAsset: dto.coverAsset,
          hostUserId,
          participantCount: 1,
          city: dto.city?.trim() || host?.profile?.location || "Hyderabad",
          maxParticipants: dto.maxParticipants,
          inviteOnly: dto.inviteOnly,
          tags: dto.tags ?? [],
        },
        select: { id: true },
      });
      await tx.vibeRoomMember.create({
        data: { roomId: room.id, userId: hostUserId, role: "Host" },
      });
      const created = await tx.vibeRoom.findUniqueOrThrow({
        where: { id: room.id },
        include: roomRelations(hostUserId),
      });
      return this.serializeRoom(created, hostUserId, true);
    });
  }

  async setSaved(clerkUserId: string, roomId: string, saved: boolean) {
    const userId = await this.databaseUserId(clerkUserId);
    const room = await this.prisma.vibeRoom.findUnique({
      where: { id: roomId },
      select: { id: true },
    });
    if (!room) throw new NotFoundException("Vibe room not found.");

    if (saved) {
      await this.prisma.vibeRoomSave.upsert({
        where: { roomId_userId: { roomId, userId } },
        create: { roomId, userId },
        update: {},
      });
    } else {
      await this.prisma.vibeRoomSave.deleteMany({ where: { roomId, userId } });
    }
    return { roomId, saved };
  }

  async join(clerkUserId: string, roomId: string) {
    return (await this.joinWithDetails(clerkUserId, roomId)).room;
  }

  /**
   * Joins a room and says whether this was a new join (not already a member),
   * so callers can announce it and notify the host exactly once.
   */
  async joinWithDetails(clerkUserId: string, roomId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    return this.prisma.$transaction(async (tx) => {
      const room = await tx.vibeRoom.findUnique({
        where: { id: roomId },
        select: {
          id: true,
          title: true,
          hostUserId: true,
          participantCount: true,
          maxParticipants: true,
          inviteOnly: true,
        },
      });
      if (!room) throw new NotFoundException("Vibe room not found.");

      const key = { roomId_userId: { roomId, userId } };
      const previousMembership = await tx.vibeRoomMember.findUnique({
        where: key,
      });
      const details = {
        userId,
        hostUserId: room.hostUserId,
        title: room.title,
      };
      if (previousMembership && previousMembership.leftAt == null) {
        const existing = await tx.vibeRoom.findUniqueOrThrow({
          where: { id: roomId },
          include: roomRelations(userId),
        });
        return {
          ...details,
          newlyJoined: false as const,
          room: this.serializeRoom(existing, userId, true),
        };
      }
      if (room.inviteOnly && !previousMembership) {
        throw new ForbiddenException("This room requires an invitation.");
      }

      const capacity = await tx.vibeRoom.updateMany({
        where: {
          id: roomId,
          participantCount: { lt: room.maxParticipants },
        },
        data: { participantCount: { increment: 1 } },
      });
      if (capacity.count === 0) {
        throw new ConflictException("This room is full.");
      }

      if (previousMembership) {
        await tx.vibeRoomMember.update({
          where: key,
          data: {
            joinedAt: new Date(),
            leftAt: null,
            role: userId === room.hostUserId ? "Host" : "Listener",
          },
        });
      } else {
        await tx.vibeRoomMember.create({
          data: {
            roomId,
            userId,
            role: userId === room.hostUserId ? "Host" : "Listener",
          },
        });
      }

      const joined = await tx.vibeRoom.findUniqueOrThrow({
        where: { id: roomId },
        include: roomRelations(userId),
      });
      return {
        ...details,
        newlyJoined: true as const,
        room: this.serializeRoom(joined, userId, true),
      };
    });
  }

  async leave(clerkUserId: string, roomId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    return this.prisma.$transaction(async (tx) => {
      const room = await tx.vibeRoom.findUnique({
        where: { id: roomId },
        select: { id: true, hostUserId: true },
      });
      if (!room) throw new NotFoundException("Vibe room not found.");

      const membership = await tx.vibeRoomMember.updateMany({
        where: { roomId, userId, leftAt: null },
        data: { leftAt: new Date() },
      });
      if (membership.count > 0) {
        await tx.vibeRoom.updateMany({
          where: { id: roomId, participantCount: { gt: 0 } },
          data: {
            participantCount: { decrement: 1 },
            ...(userId === room.hostUserId ? { isLive: false } : {}),
          },
        });
      }

      const updated = await tx.vibeRoom.findUniqueOrThrow({
        where: { id: roomId },
        include: roomRelations(userId),
      });
      return this.serializeRoom(updated, userId, false);
    });
  }
  /** Host-only: edits the room's details or takes it live. */
  async update(clerkUserId: string, roomId: string, dto: UpdateVibeRoomDto) {
    const userId = await this.databaseUserId(clerkUserId);
    return this.prisma.$transaction(async (tx) => {
      const room = await tx.vibeRoom.findUnique({
        where: { id: roomId },
        select: { hostUserId: true },
      });
      if (!room) throw new NotFoundException("Vibe room not found.");
      if (room.hostUserId !== userId) {
        throw new ForbiddenException("Only the host can edit this room.");
      }
      const updated = await tx.vibeRoom.update({
        where: { id: roomId },
        data: {
          title: dto.title?.trim(),
          description: dto.description?.trim(),
          categoryId: dto.categoryId,
          emoji: dto.emoji,
          maxParticipants: dto.maxParticipants,
          inviteOnly: dto.inviteOnly,
          isLive: dto.isLive,
          // A room that goes live is no longer scheduled for later.
          ...(dto.isLive ? { scheduledFor: null } : {}),
        },
        include: roomRelations(userId),
      });
      const joined = await tx.vibeRoomMember.count({
        where: { roomId, userId, leftAt: null },
      });
      return this.serializeRoom(updated, userId, joined > 0);
    });
  }

  /**
   * Host-only: deletes the room with its members, messages and games.
   * Returns who was in it and the stored voice notes, so the caller can
   * clean up live connections and media after the delete is saved.
   */
  async delete(clerkUserId: string, roomId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    return this.prisma.$transaction(async (tx) => {
      const room = await tx.vibeRoom.findUnique({
        where: { id: roomId },
        select: { hostUserId: true },
      });
      if (!room) throw new NotFoundException("Vibe room not found.");
      if (room.hostUserId !== userId) {
        throw new ForbiddenException("Only the host can delete this room.");
      }
      const members = await tx.vibeRoomMember.findMany({
        where: { roomId, leftAt: null },
        select: { userId: true },
      });
      const media = await tx.vibeRoomMessage.findMany({
        where: { roomId, mediaPublicId: { not: null } },
        select: { mediaPublicId: true },
      });
      await tx.vibeRoom.delete({ where: { id: roomId } });
      return {
        memberIds: members.map((member) => member.userId),
        mediaPublicIds: media.flatMap(({ mediaPublicId }) =>
          mediaPublicId ? [mediaPublicId] : [],
        ),
      };
    });
  }

  /**
   * The rooms this member is in, as group chats for the Chat tab: each with
   * its latest message and how many messages arrived since they last read it.
   * Newest activity first.
   */
  async chats(clerkUserId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    const memberships = await this.prisma.vibeRoomMember.findMany({
      where: { userId, leftAt: null },
      select: {
        joinedAt: true,
        lastReadAt: true,
        room: { include: roomRelations(userId) },
      },
    });
    const chats = await Promise.all(
      memberships.map(async ({ room, joinedAt, lastReadAt }) => {
        const [last, unreadCount] = await Promise.all([
          this.prisma.vibeRoomMessage.findFirst({
            where: { roomId: room.id },
            orderBy: [{ createdAt: "desc" }, { id: "desc" }],
            select: {
              text: true,
              kind: true,
              createdAt: true,
              senderId: true,
              sender: {
                select: { firstName: true, lastName: true, username: true },
              },
            },
          }),
          this.prisma.vibeRoomMessage.count({
            where: {
              roomId: room.id,
              kind: { in: ["text", "voice"] },
              senderId: { not: userId },
              createdAt: { gt: lastReadAt ?? joinedAt },
            },
          }),
        ]);
        const lastActivityAt = last?.createdAt ?? joinedAt;
        return {
          room: this.serializeRoom(room, userId, true),
          unreadCount,
          lastActivityAt: lastActivityAt.toISOString(),
          lastMessage: last
            ? {
                kind: last.kind,
                text: last.text,
                isMe: last.senderId === userId,
                sender:
                  this.name(last.sender) || last.sender.username || "Member",
              }
            : null,
        };
      }),
    );
    return chats.sort((a, b) =>
      b.lastActivityAt.localeCompare(a.lastActivityAt),
    );
  }

  /** Everything in the room up to now counts as read for this member. */
  async markRead(clerkUserId: string, roomId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    await this.prisma.vibeRoomMember.updateMany({
      where: { roomId, userId, leftAt: null },
      data: { lastReadAt: new Date() },
    });
    return { read: true };
  }

  private serializeRoom(
    room: RoomWithRelations,
    viewerId: string,
    isJoined = room.members.some((member) => member.userId === viewerId),
  ) {
    const hostName = this.name(room.host);
    return {
      id: room.id,
      title: room.title,
      description: room.description,
      categoryId: room.categoryId,
      emoji: room.emoji,
      coverAsset: room.coverAsset,
      hostUserId: room.hostUserId,
      hostName: hostName || room.host.username || "Member",
      hostAvatar: this.avatar(room.host),
      participantCount: room.participantCount,
      city: room.city,
      isLive: room.isLive,
      isHostedByMe: room.hostUserId === viewerId,
      isJoined,
      inviteOnly: room.inviteOnly,
      maxParticipants: room.maxParticipants,
      scheduledFor: room.scheduledFor,
      tags: room.tags,
      members: room.members.map((member) => ({
        id: member.user.id,
        name: this.name(member.user) || member.user.username || "Member",
        age: this.age(member.user.onboardingProfile?.birthDate ?? null),
        avatar: this.avatar(member.user),
        bio: member.user.profile?.bio ?? "",
        tags: member.user.onboardingProfile?.interests ?? [],
        role: member.role,
        online: this.isOnline(member.user.lastActiveAt),
      })),
      messages: [],
      isSaved: room.saves.length > 0,
    };
  }

  private name(user: { firstName: string | null; lastName: string | null }) {
    return [user.firstName, user.lastName]
      .filter((part): part is string => Boolean(part?.trim()))
      .join(" ");
  }

  private avatar(user: {
    imageUrl: string | null;
    profile: { photos: { secureUrl: string }[] } | null;
  }) {
    return (
      user.profile?.photos[0]?.secureUrl ?? user.imageUrl ?? fallbackAvatar
    );
  }

  private age(birthDate: Date | null) {
    if (!birthDate) return 0;
    const now = new Date();
    let years = now.getFullYear() - birthDate.getFullYear();
    if (
      now.getMonth() < birthDate.getMonth() ||
      (now.getMonth() === birthDate.getMonth() &&
        now.getDate() < birthDate.getDate())
    ) {
      years--;
    }
    return years;
  }

  private isOnline(lastActiveAt: Date | null) {
    return Boolean(
      lastActiveAt && Date.now() - lastActiveAt.getTime() < 5 * 60 * 1000,
    );
  }
}
