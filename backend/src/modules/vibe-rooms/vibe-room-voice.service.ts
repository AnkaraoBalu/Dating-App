import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { TrackSource, TrackType } from "livekit-server-sdk";
import { PrismaService } from "../../database/prisma.service";
import { LiveKitService } from "../livekit/livekit.service";

const fallbackAvatar = "assets/images/boys-images/golden_hour_white_shirt.png";

@Injectable()
export class VibeRoomVoiceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly liveKit: LiveKitService,
  ) {}
  async createJoinToken(clerkUserId: string, roomId: string) {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: {
        id: true,
        username: true,
        firstName: true,
        lastName: true,
        imageUrl: true,
        profile: {
          select: {
            photos: {
              orderBy: { position: "asc" },
              take: 1,
              select: { secureUrl: true },
            },
          },
        },
      },
    });
    if (!user) {
      throw new NotFoundException("User not synced yet. Open /users/me first.");
    }

    const membership = await this.prisma.vibeRoomMember.findUnique({
      where: { roomId_userId: { roomId, userId: user.id } },
      select: { leftAt: true, role: true },
    });
    if (!membership || membership.leftAt !== null) {
      throw new ForbiddenException(
        "Join this Vibe room before starting voice.",
      );
    }

    const name =
      [user.firstName, user.lastName]
        .filter((part): part is string => Boolean(part?.trim()))
        .join(" ") ||
      user.username ||
      "Member";
    const avatar =
      user.profile?.photos[0]?.secureUrl ?? user.imageUrl ?? fallbackAvatar;
    const join = await this.liveKit.joinToken({
      room: roomId,
      identity: user.id,
      name,
      metadata: { avatar, role: membership.role },
    });
    return {
      ...join,
      participant: { identity: user.id, name, avatar, role: membership.role },
    };
  }

  /**
   * Host-only: server-side mutes a member's microphone. They can unmute
   * themselves again, as in other audio rooms.
   */
  async muteParticipant(
    clerkUserId: string,
    roomId: string,
    participantId: string,
  ) {
    const userId = await this.databaseUserId(clerkUserId);
    const room = await this.prisma.vibeRoom.findUnique({
      where: { id: roomId },
      select: { hostUserId: true },
    });
    if (!room) throw new NotFoundException("Vibe room not found.");
    if (room.hostUserId !== userId) {
      throw new ForbiddenException("Only the host can mute people.");
    }

    const service = this.liveKit.rooms();
    const participant = await service
      .getParticipant(roomId, participantId)
      .catch(() => {
        throw new NotFoundException("That person is not in voice right now.");
      });
    const microphones = participant.tracks.filter(
      (track) =>
        track.type === TrackType.AUDIO &&
        track.source === TrackSource.MICROPHONE &&
        !track.muted,
    );
    for (const track of microphones) {
      await service.mutePublishedTrack(roomId, participantId, track.sid, true);
    }
    return { muted: true };
  }

  /**
   * Best effort: drops a member who left the Vibe room from its voice call,
   * so leaving on one screen or device also ends their audio.
   */
  removeParticipant(roomId: string, userId: string) {
    return this.liveKit.removeParticipant(roomId, userId);
  }

  /** Best effort: ends a deleted room's voice call for everyone. */
  closeRoom(roomId: string) {
    return this.liveKit.deleteRoom(roomId);
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
}
