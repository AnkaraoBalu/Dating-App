import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";
import { ProfileRepository } from "./profile.repository";

@Injectable()
export class ProfileConnectionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly profiles: ProfileRepository,
  ) {}
  async like(clerkUserId: string, targetUserId: string) {
    const [fromUser, targetUser] = await Promise.all([
      this.prisma.user.findUnique({
        where: { clerkUserId },
        select: { id: true },
      }),
      this.prisma.user.findUnique({
        where: { id: targetUserId },
        select: { id: true, profile: { select: { completedAt: true } } },
      }),
    ]);
    if (!fromUser) throw new NotFoundException("User profile not found.");
    if (!targetUser?.profile?.completedAt || fromUser.id === targetUser.id) {
      throw new NotFoundException("Profile not found.");
    }
    await this.prisma.profileLike.upsert({
      where: {
        fromUserId_toUserId: {
          fromUserId: fromUser.id,
          toUserId: targetUser.id,
        },
      },
      create: { fromUserId: fromUser.id, toUserId: targetUser.id },
      update: {},
    });
    const reciprocal = await this.prisma.profileLike.findUnique({
      where: {
        fromUserId_toUserId: {
          fromUserId: targetUser.id,
          toUserId: fromUser.id,
        },
      },
      select: { id: true },
    });
    return { liked: true, isMatch: reciprocal != null };
  }

  async pass(clerkUserId: string, targetUserId: string) {
    const [fromUser, targetUser] = await Promise.all([
      this.prisma.user.findUnique({
        where: { clerkUserId },
        select: { id: true },
      }),
      this.prisma.user.findUnique({
        where: { id: targetUserId },
        select: { id: true, profile: { select: { completedAt: true } } },
      }),
    ]);
    if (!fromUser) throw new NotFoundException("User profile not found.");
    if (!targetUser?.profile?.completedAt || fromUser.id === targetUser.id) {
      throw new NotFoundException("Profile not found.");
    }
    await this.prisma.profilePass.upsert({
      where: {
        fromUserId_toUserId: {
          fromUserId: fromUser.id,
          toUserId: targetUser.id,
        },
      },
      create: { fromUserId: fromUser.id, toUserId: targetUser.id },
      update: {},
    });
    return { passed: true };
  }

  async insights(clerkUserId: string) {
    const userId = await this.profiles.userId(clerkUserId);
    const [likesReceived, likesSent, matches] = await Promise.all([
      this.prisma.profileLike.count({ where: { toUserId: userId } }),
      this.prisma.profileLike.count({ where: { fromUserId: userId } }),
      this.prisma.profileLike.count({
        where: {
          fromUserId: userId,
          toUser: { likesSent: { some: { toUserId: userId } } },
        },
      }),
    ]);
    return { likesReceived, likesSent, matches };
  }

  async listIncomingLikes(clerkUserId: string) {
    const userId = await this.profiles.userId(clerkUserId);
    const likes = await this.prisma.profileLike.findMany({
      where: {
        toUserId: userId,
        fromUser: { likesSent: { none: { toUserId: userId } } },
      },
      include: {
        fromUser: {
          include: {
            profile: {
              include: {
                photos: { orderBy: { position: "asc" } },
              },
            },
            onboardingProfile: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });
    return likes.map((like) => {
      const person = like.fromUser;
      const profile = person.profile;
      const onboarding = person.onboardingProfile;
      const photos = profile?.photos.map((photo) => photo.secureUrl) ?? [];
      const now = new Date();
      const birthDate = onboarding?.birthDate;
      let age = 18;
      if (birthDate) {
        age = now.getUTCFullYear() - birthDate.getUTCFullYear();
        if (
          now.getUTCMonth() < birthDate.getUTCMonth() ||
          (now.getUTCMonth() === birthDate.getUTCMonth() &&
            now.getUTCDate() < birthDate.getUTCDate())
        )
          age--;
      }
      return {
        id: person.id,
        likedAt: like.createdAt,
        profile: {
          id: person.id,
          name: person.username?.trim() || "Matchify member",
          age,
          image: photos[0] ?? "",
          photos,
          distance:
            profile?.showDistance === false
              ? "Distance hidden"
              : (profile?.location ?? "Nearby"),
          bio: profile?.bio ?? "",
          interests: [
            ...new Set([
              ...(onboarding?.interests ?? []),
              ...(onboarding?.musicGenres ?? []),
              ...(onboarding?.favoriteArtists ?? []),
            ]),
          ].slice(0, 6),
          online:
            profile?.showOnlineStatus === true &&
            person.lastActiveAt != null &&
            person.lastActiveAt >= new Date(now.getTime() - 2 * 60 * 1000),
          verified: profile?.verificationStatus === "verified",
        },
      };
    });
  }

  async listMatches(clerkUserId: string, search?: string) {
    const userId = await this.profiles.userId(clerkUserId);
    const reciprocal = await this.prisma.profileLike.findMany({
      where: {
        fromUserId: userId,
        toUser: { likesSent: { some: { toUserId: userId } } },
      },
      include: {
        toUser: {
          include: {
            profile: {
              include: {
                photos: { orderBy: { position: "asc" } },
                prompts: { orderBy: { position: "asc" } },
              },
            },
            onboardingProfile: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });
    const conversations = await this.prisma.conversation.findMany({
      where: { OR: [{ userOneId: userId }, { userTwoId: userId }] },
      include: {
        messages: {
          orderBy: [{ createdAt: "desc" }, { id: "desc" }],
          take: 1,
        },
      },
    });
    const conversationByPeerId = new Map(
      conversations.map((conversation) => [
        conversation.userOneId === userId
          ? conversation.userTwoId
          : conversation.userOneId,
        conversation,
      ]),
    );
    const normalizedSearch = search?.trim().toLocaleLowerCase();
    return reciprocal
      .filter((like) => {
        const name = like.toUser.username?.trim() || "Matchify member";
        return (
          !normalizedSearch ||
          name.toLocaleLowerCase().includes(normalizedSearch)
        );
      })
      .map((like) => {
        const profile = like.toUser.profile;
        const onboarding = like.toUser.onboardingProfile;
        const birthDate = onboarding?.birthDate;
        const now = new Date();
        let age = 18;
        if (birthDate) {
          age = now.getUTCFullYear() - birthDate.getUTCFullYear();
          if (
            now.getUTCMonth() < birthDate.getUTCMonth() ||
            (now.getUTCMonth() === birthDate.getUTCMonth() &&
              now.getUTCDate() < birthDate.getUTCDate())
          )
            age--;
        }
        const photos = profile?.photos.map((photo) => photo.secureUrl) ?? [];
        const interests = [
          ...(onboarding?.interests ?? []),
          ...(onboarding?.musicGenres ?? []),
          ...(onboarding?.favoriteArtists ?? []),
        ];
        const conversation = conversationByPeerId.get(like.toUserId);
        const latestMessage = conversation?.messages[0];
        const unreadCount = conversation
          ? conversation.userOneId === userId
            ? conversation.userOneUnreadCount
            : conversation.userTwoUnreadCount
          : 0;
        return {
          id: like.toUserId,
          conversationId: conversation?.id,
          isNew: now.getTime() - like.createdAt.getTime() < 24 * 60 * 60 * 1000,
          unreadCount,
          lastMessage: latestMessage
            ? latestMessage.text ||
              (latestMessage.type === "image"
                ? "Photo"
                : latestMessage.type === "location"
                  ? "Location"
                  : "Message")
            : null,
          lastActivityAt: (
            latestMessage?.createdAt ?? like.createdAt
          ).toISOString(),
          profile: {
            id: like.toUserId,
            name: like.toUser.username?.trim() || "Matchify member",
            age,
            image: photos[0] ?? "",
            photos,
            distance:
              profile?.showDistance === false
                ? "Distance hidden"
                : (profile?.location ?? "Nearby"),
            bio: profile?.bio ?? "",
            interests: [...new Set(interests)].slice(0, 6),
            online:
              profile?.showOnlineStatus === true &&
              like.toUser.lastActiveAt != null &&
              like.toUser.lastActiveAt >=
                new Date(now.getTime() - 2 * 60 * 1000),
            verified: profile?.verificationStatus === "verified",
          },
        };
      });
  }
}
