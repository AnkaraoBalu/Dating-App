import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { createClerkClient } from "@clerk/backend";
import { ConfigService } from "@nestjs/config";
import { PrismaService } from "../../database/prisma.service";
import { UpdateOnboardingDto } from "./dto/update-onboarding.dto";
import { UpdateNameDto } from "./dto/update-name.dto";

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly clerk;

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
  ) {
    this.clerk = createClerkClient({
      secretKey: config.getOrThrow<string>("CLERK_SECRET_KEY"),
    });
  }

  async syncFromClerk(clerkUserId: string) {
    if (clerkUserId.startsWith("demo_matchify_")) {
      const demoUser = await this.prisma.user.findUnique({
        where: { clerkUserId },
        include: { onboardingProfile: true },
      });
      if (!demoUser) throw new NotFoundException("Demo profile not found.");
      return demoUser;
    }
    this.logger.log(`Syncing authenticated Clerk user ${clerkUserId}`);
    try {
      const clerkUser = await this.clerk.users.getUser(clerkUserId);
      const primaryEmail = clerkUser.emailAddresses.find(
        (email) => email.id === clerkUser.primaryEmailAddressId,
      )?.emailAddress;
      const primaryPhone = clerkUser.phoneNumbers.find(
        (phone) => phone.id === clerkUser.primaryPhoneNumberId,
      )?.phoneNumber;

      const user = await this.prisma.user.upsert({
        where: { clerkUserId },
        create: {
          clerkUserId,
          email: primaryEmail,
          phoneNumber: primaryPhone,
          firstName: clerkUser.firstName,
          lastName: clerkUser.lastName,
          imageUrl: clerkUser.imageUrl,
        },
        update: {
          email: primaryEmail,
          phoneNumber: primaryPhone,
          firstName: clerkUser.firstName,
          lastName: clerkUser.lastName,
          imageUrl: clerkUser.imageUrl,
        },
        include: { onboardingProfile: true },
      });
      this.logger.log(`User sync succeeded for Clerk user ${clerkUserId}`);
      return user;
    } catch (error) {
      const reason =
        error instanceof Error ? error.message : "Unknown sync error";
      this.logger.error(
        `User sync failed for Clerk user ${clerkUserId}: ${reason}`,
      );
      throw error;
    }
  }

  async updateOnboarding(clerkUserId: string, dto: UpdateOnboardingDto) {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User profile not found");

    if (dto.birthDate && !this.isAdult(new Date(dto.birthDate))) {
      throw new BadRequestException("You must be at least 18 years old.");
    }
    if (
      dto.musicGenres &&
      dto.musicGenres.some((genre) =>
        ["a_bit_of_everything", "not_big_on_music"].includes(genre),
      ) &&
      (dto.musicGenres.length > 1 || (dto.favoriteArtists?.length ?? 0) > 0)
    ) {
      throw new BadRequestException(
        "Choose a general music option by itself, or select specific genres.",
      );
    }
    if (
      dto.musicGenres &&
      dto.favoriteArtists &&
      dto.musicGenres.length + dto.favoriteArtists.length > 5
    ) {
      throw new BadRequestException(
        "Choose up to five artists and genres combined.",
      );
    }
    if (
      dto.dealbreakers?.includes("no_hard_dealbreakers") &&
      dto.dealbreakers.length > 1
    ) {
      throw new BadRequestException(
        "Choose no hard deal-breakers by itself, or select specific values.",
      );
    }
    const data = {
      ...(dto.birthDate ? { birthDate: new Date(dto.birthDate) } : {}),
      ...(dto.genderIdentity ? { genderIdentity: dto.genderIdentity } : {}),
      ...(dto.interestedIn ? { interestedIn: dto.interestedIn } : {}),
      ...(dto.datingIntentions !== undefined
        ? { datingIntentions: dto.datingIntentions }
        : {}),
      ...(dto.skippedQuestions !== undefined
        ? { skippedQuestions: dto.skippedQuestions }
        : {}),
      ...(dto.vibeType !== undefined ? { vibeType: dto.vibeType } : {}),
      ...(dto.idealFriday !== undefined
        ? { idealFriday: dto.idealFriday }
        : {}),
      ...(dto.interests ? { interests: dto.interests } : {}),
      ...(dto.musicGenres ? { musicGenres: dto.musicGenres } : {}),
      ...(dto.favoriteArtists ? { favoriteArtists: dto.favoriteArtists } : {}),
      ...(dto.currentEra !== undefined ? { currentEra: dto.currentEra } : {}),
      ...(dto.dealbreakers ? { dealbreakers: dto.dealbreakers } : {}),
      ...(dto.preferredDistanceKm !== undefined
        ? { preferredDistanceKm: dto.preferredDistanceKm }
        : {}),
      ...(dto.onlyShowPeopleNearby !== undefined
        ? { onlyShowPeopleNearby: dto.onlyShowPeopleNearby }
        : {}),
      ...(dto.locationPermissionGranted !== undefined
        ? { locationPermissionGranted: dto.locationPermissionGranted }
        : {}),
      ...(dto.latitude !== undefined ? { latitude: dto.latitude } : {}),
      ...(dto.longitude !== undefined ? { longitude: dto.longitude } : {}),
    };

    return this.prisma.onboardingProfile.upsert({
      where: { userId: user.id },
      create: { userId: user.id, ...data },
      update: data,
    });
  }

  async updateName(clerkUserId: string, dto: UpdateNameDto) {
    const username = dto.username.trim();
    if (!username) throw new BadRequestException("Enter your name.");
    const user = await this.syncFromClerk(clerkUserId);
    return this.prisma.user.update({
      where: { id: user.id },
      data: { username },
    });
  }

  async recordActivity(clerkUserId: string) {
    const result = await this.prisma.user.updateMany({
      where: { clerkUserId },
      data: { lastActiveAt: new Date() },
    });
    if (result.count === 0)
      throw new NotFoundException("User profile not found");
    return { active: true };
  }

  async completeOnboarding(clerkUserId: string) {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User profile not found");

    const profile = await this.prisma.onboardingProfile.findUnique({
      where: { userId: user.id },
    });
    if (
      !profile?.birthDate ||
      !this.isAdult(profile.birthDate) ||
      !profile.genderIdentity ||
      !profile.interestedIn
    ) {
      throw new BadRequestException("Complete all onboarding questions first.");
    }

    return this.prisma.onboardingProfile.update({
      where: { userId: user.id },
      data: { completedAt: new Date() },
    });
  }

  private isAdult(birthDate: Date): boolean {
    const today = new Date();
    let age = today.getUTCFullYear() - birthDate.getUTCFullYear();
    const birthdayHasNotOccurredThisYear =
      today.getUTCMonth() < birthDate.getUTCMonth() ||
      (today.getUTCMonth() === birthDate.getUTCMonth() &&
        today.getUTCDate() < birthDate.getUTCDate());
    if (birthdayHasNotOccurredThisYear) age -= 1;
    return age >= 18;
  }
}
