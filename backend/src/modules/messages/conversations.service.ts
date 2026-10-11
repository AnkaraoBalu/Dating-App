import { Injectable } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";
import { MessagesService } from "./messages.service";

/** Builds the conversation list: peers, latest message previews and unread counts. */
@Injectable()
export class ConversationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly messages: MessagesService,
  ) {}

  async listConversations(clerkUserId: string, search?: string) {
    const userId = await this.messages.userId(clerkUserId);
    const conversations = await this.prisma.conversation.findMany({
      where: { OR: [{ userOneId: userId }, { userTwoId: userId }] },
      include: {
        userOne: {
          select: {
            id: true,
            username: true,
            lastActiveAt: true,
            profile: {
              select: {
                location: true,
                bio: true,
                showDistance: true,
                showOnlineStatus: true,
                verificationStatus: true,
                photos: {
                  select: { secureUrl: true },
                  orderBy: { position: "asc" },
                },
              },
            },
            onboardingProfile: {
              select: {
                birthDate: true,
                interests: true,
                musicGenres: true,
                favoriteArtists: true,
              },
            },
          },
        },
        userTwo: {
          select: {
            id: true,
            username: true,
            lastActiveAt: true,
            profile: {
              select: {
                location: true,
                bio: true,
                showDistance: true,
                showOnlineStatus: true,
                verificationStatus: true,
                photos: {
                  select: { secureUrl: true },
                  orderBy: { position: "asc" },
                },
              },
            },
            onboardingProfile: {
              select: {
                birthDate: true,
                interests: true,
                musicGenres: true,
                favoriteArtists: true,
              },
            },
          },
        },
        messages: {
          select: { id: true, text: true, type: true, createdAt: true },
          orderBy: [{ createdAt: "desc" }, { id: "desc" }],
          take: 1,
        },
      },
      orderBy: [{ updatedAt: "desc" }, { id: "desc" }],
    });
    const normalizedSearch = search?.trim().toLocaleLowerCase();
    const now = new Date();
    return conversations.flatMap((conversation) => {
      const peer =
        conversation.userOneId === userId
          ? conversation.userTwo
          : conversation.userOne;
      const profile = peer.profile;
      const onboarding = peer.onboardingProfile;
      const name = peer.username?.trim() || "Matchify member";
      if (
        normalizedSearch &&
        !name.toLocaleLowerCase().includes(normalizedSearch) &&
        !this.previewText(
          conversation.messages[0]?.type ?? "",
          conversation.messages[0]?.text ?? "",
        )
          .toLocaleLowerCase()
          .includes(normalizedSearch)
      ) {
        return [];
      }
      const photos = profile?.photos.map(({ secureUrl }) => secureUrl) ?? [];
      const birthDate = onboarding?.birthDate;
      let age: number | null = null;
      if (birthDate) {
        age = now.getUTCFullYear() - birthDate.getUTCFullYear();
        if (
          now.getUTCMonth() < birthDate.getUTCMonth() ||
          (now.getUTCMonth() === birthDate.getUTCMonth() &&
            now.getUTCDate() < birthDate.getUTCDate())
        )
          age--;
      }
      const lastMessage = conversation.messages[0];
      const unreadCount =
        conversation.userOneId === userId
          ? conversation.userOneUnreadCount
          : conversation.userTwoUnreadCount;
      const interests = [
        ...(onboarding?.interests ?? []),
        ...(onboarding?.musicGenres ?? []),
        ...(onboarding?.favoriteArtists ?? []),
      ];
      return [
        {
          id: peer.id,
          conversationId: conversation.id,
          isNew:
            !lastMessage &&
            now.getTime() - conversation.createdAt.getTime() <
              24 * 60 * 60 * 1000,
          unreadCount,
          lastMessage: lastMessage
            ? this.previewText(lastMessage.type, lastMessage.text)
            : "Say hello 👋",
          lastActivityAt: (
            lastMessage?.createdAt ?? conversation.updatedAt
          ).toISOString(),
          profile: {
            id: peer.id,
            name,
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
              peer.lastActiveAt != null &&
              peer.lastActiveAt >= new Date(now.getTime() - 2 * 60 * 1000),
            verified: profile?.verificationStatus === "verified",
          },
        },
      ];
    });
  }

  private previewText(type: string, text: string) {
    if (text.trim()) return text;
    if (type === "image") return "Photo";
    if (type === "location") return "Location";
    if (type === "voice") return "Voice message";
    return "Message";
  }
}
