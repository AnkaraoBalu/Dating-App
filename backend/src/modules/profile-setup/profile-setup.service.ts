import { Injectable, BadRequestException } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";
import {
  UpdateProfileDto,
  SavePromptsDto,
  ReorderPhotosDto,
} from "./dto/profile-setup.dto";
import { DiscoverProfilesQueryDto } from "./dto/discover-profiles.dto";
import { ProfileRepository } from "./profile.repository";
import { ProfileDiscoveryService } from "./profile-discovery.service";
import { ProfilePhotosService } from "./profile-photos.service";
import { ProfileConnectionsService } from "./profile-connections.service";

@Injectable()
export class ProfileSetupService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly profiles: ProfileRepository,
    private readonly discovery: ProfileDiscoveryService,
    private readonly photos: ProfilePhotosService,
    private readonly connections: ProfileConnectionsService,
  ) {}
  get(userId: string) {
    return this.profiles.get(userId);
  }
  discover(userId: string, query: DiscoverProfilesQueryDto) {
    return this.discovery.discover(userId, query);
  }
  like(userId: string, targetId: string) {
    return this.connections.like(userId, targetId);
  }
  pass(userId: string, targetId: string) {
    return this.connections.pass(userId, targetId);
  }
  insights(userId: string) {
    return this.connections.insights(userId);
  }
  matches(userId: string, search?: string) {
    return this.connections.listMatches(userId, search);
  }
  incomingLikes(userId: string) {
    return this.connections.listIncomingLikes(userId);
  }
  addPhoto(userId: string, file?: Express.Multer.File) {
    return this.photos.addPhoto(userId, file);
  }
  replacePhoto(userId: string, photoId: string, file?: Express.Multer.File) {
    return this.photos.replacePhoto(userId, photoId, file);
  }
  removePhoto(userId: string, photoId: string) {
    return this.photos.removePhoto(userId, photoId);
  }
  reorderPhotos(userId: string, dto: ReorderPhotosDto) {
    return this.photos.reorderPhotos(userId, dto);
  }
  async update(clerkUserId: string, dto: UpdateProfileDto) {
    const profile = await this.profiles.ensureProfile(clerkUserId);
    return this.prisma.profile.update({
      where: { id: profile.id },
      data: dto,
      include: {
        photos: { orderBy: { position: "asc" } },
        prompts: { orderBy: { position: "asc" } },
      },
    });
  }

  async savePrompts(clerkUserId: string, dto: SavePromptsDto) {
    const profile = await this.profiles.ensureProfile(clerkUserId);
    const prompts = dto.prompts.map((item, position) => ({
      profileId: profile.id,
      question: item.question.trim(),
      answer: item.answer.trim(),
      position,
    }));
    if (
      prompts.some((item) => !item.question || !item.answer) ||
      new Set(prompts.map((item) => item.question)).size !== prompts.length
    ) {
      throw new BadRequestException(
        "Prompts require distinct questions and nonempty answers.",
      );
    }
    return this.prisma.$transaction(async (tx) => {
      await tx.profilePrompt.deleteMany({ where: { profileId: profile.id } });
      if (prompts.length) await tx.profilePrompt.createMany({ data: prompts });
      return tx.profile.findUniqueOrThrow({
        where: { id: profile.id },
        include: {
          photos: { orderBy: { position: "asc" } },
          prompts: { orderBy: { position: "asc" } },
        },
      });
    });
  }

  async complete(clerkUserId: string) {
    const profile = await this.profiles.get(clerkUserId);
    if (profile.photos.length < 4 || profile.prompts.length < 3) {
      throw new BadRequestException(
        "Add at least 4 photos and answer at least 3 prompts.",
      );
    }
    await this.prisma.profile.update({
      where: { id: profile.id },
      data: { completedAt: new Date() },
    });
    return this.profiles.get(clerkUserId);
  }
}
