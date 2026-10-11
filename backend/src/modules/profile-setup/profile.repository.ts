import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";

@Injectable()
export class ProfileRepository {
  constructor(private readonly prisma: PrismaService) {}
  async userId(clerkUserId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user)
      throw new NotFoundException("User not synced yet. Open /users/me first.");
    return user.id;
  }

  async ensureProfile(clerkUserId: string) {
    const existing = await this.prisma.profile.findFirst({
      where: { user: { clerkUserId } },
    });
    if (existing) return existing;
    const userId = await this.userId(clerkUserId);
    return this.prisma.profile.upsert({
      where: { userId },
      create: { userId },
      update: {},
    });
  }

  async get(clerkUserId: string) {
    const profile = await this.ensureProfile(clerkUserId);
    return this.prisma.profile.findUniqueOrThrow({
      where: { id: profile.id },
      include: {
        photos: { orderBy: { position: "asc" } },
        prompts: { orderBy: { position: "asc" } },
        user: {
          select: { username: true, firstName: true, lastName: true, onboardingProfile: true },
        },
      },
    });
  }
}
