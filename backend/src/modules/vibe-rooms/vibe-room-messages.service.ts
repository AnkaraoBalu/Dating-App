import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../../database/prisma.service";
import {
  CreateVibeRoomMessageDto,
  ListVibeRoomMessagesQueryDto,
} from "./dto/vibe-room.dto";

const fallbackAvatar = "assets/images/boys-images/golden_hour_white_shirt.png";

const messageRelations = {
  sender: {
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
} satisfies Prisma.VibeRoomMessageInclude;

type MessageWithSender = Prisma.VibeRoomMessageGetPayload<{
  include: typeof messageRelations;
}>;

@Injectable()
export class VibeRoomMessagesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(
    clerkUserId: string,
    roomId: string,
    query: ListVibeRoomMessagesQueryDto,
  ) {
    const userId = await this.databaseUserId(clerkUserId);
    await this.assertMember(userId, roomId);
    const messages = await this.prisma.vibeRoomMessage.findMany({
      where: { roomId },
      include: messageRelations,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: query.limit,
    });
    return messages.reverse().map((message) => this.serialize(message, userId));
  }

  async send(
    clerkUserId: string,
    roomId: string,
    dto: CreateVibeRoomMessageDto,
  ) {
    const userId = await this.databaseUserId(clerkUserId);
    await this.assertMember(userId, roomId);
    const text = dto.text.trim();
    if (!text) throw new BadRequestException("Message cannot be empty.");

    let message: MessageWithSender;
    try {
      message = await this.prisma.vibeRoomMessage.create({
        data: {
          roomId,
          senderId: userId,
          clientMessageId: dto.clientMessageId,
          text,
        },
        include: messageRelations,
      });
    } catch (error) {
      const duplicate = await this.prisma.vibeRoomMessage.findUnique({
        where: {
          senderId_clientMessageId: {
            senderId: userId,
            clientMessageId: dto.clientMessageId,
          },
        },
        include: messageRelations,
      });
      if (!duplicate || duplicate.roomId !== roomId) throw error;
      message = duplicate;
    }
    return this.serialize(message, userId);
  }

  private async databaseUserId(clerkUserId: string) {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) {
      throw new NotFoundException("User not synced yet. Open /users/me first.");
    }
    return user.id;
  }

  private async assertMember(userId: string, roomId: string) {
    const membership = await this.prisma.vibeRoomMember.findUnique({
      where: { roomId_userId: { roomId, userId } },
      select: { leftAt: true },
    });
    if (membership && membership.leftAt === null) return;

    const room = await this.prisma.vibeRoom.findUnique({
      where: { id: roomId },
      select: { id: true },
    });
    if (!room) throw new NotFoundException("Vibe room not found.");
    throw new ForbiddenException("Join this room before viewing its chat.");
  }

  private serialize(message: MessageWithSender, viewerId: string) {
    const sender = message.sender;
    const senderName = [sender.firstName, sender.lastName]
      .filter((part): part is string => Boolean(part?.trim()))
      .join(" ");
    return {
      id: message.id,
      clientMessageId: message.clientMessageId,
      senderId: message.senderId,
      sender: senderName || sender.username || "Member",
      avatar:
        sender.profile?.photos[0]?.secureUrl ??
        sender.imageUrl ??
        fallbackAvatar,
      text: message.text,
      time: message.createdAt.toISOString(),
      isMe: message.senderId === viewerId,
    };
  }
}
