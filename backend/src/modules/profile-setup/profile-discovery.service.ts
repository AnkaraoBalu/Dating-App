import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";
import { DiscoverProfilesQueryDto } from "./dto/discover-profiles.dto";
import { discoveryCityCenter } from "./discovery-location";
import { SafetyService } from "../safety/safety.service";

@Injectable()
export class ProfileDiscoveryService {
  constructor(private readonly prisma: PrismaService) {}
  async discover(clerkUserId: string, query: DiscoverProfilesQueryDto) {
    // Load the member and who they already liked/passed in parallel.
    const [current, sentLikes, sentPasses] = await Promise.all([
      this.prisma.user.findUnique({
        where: { clerkUserId },
        include: {
          onboardingProfile: true,
          profile: { select: { location: true } },
        },
      }),
      this.prisma.profileLike.findMany({
        where: { fromUser: { clerkUserId } },
        select: { toUserId: true },
      }),
      this.prisma.profilePass.findMany({
        where: { fromUser: { clerkUserId } },
        select: { toUserId: true },
      }),
    ]);
    if (!current?.onboardingProfile?.completedAt) {
      throw new NotFoundException(
        "Complete onboarding before discovering profiles.",
      );
    }
    if (
      !current.onboardingProfile.genderIdentity ||
      !current.onboardingProfile.interestedIn
    ) {
      throw new BadRequestException(
        "Complete your gender and preferences before discovering profiles.",
      );
    }

    const requestedInterests = [
      ...new Set(
        [
          ...(query.interest ? [query.interest] : []),
          ...(query.interests ?? []),
        ]
          .map((interest) => this.normalize(interest))
          .filter(Boolean),
      ),
    ];
    const now = new Date();
    const onlineAfter = new Date(now.getTime() - 2 * 60 * 1000);
    const travelLocation = query.location?.trim() || undefined;
    if ((query.latitude == null) !== (query.longitude == null)) {
      throw new BadRequestException("Provide both latitude and longitude.");
    }
    const travelCenter = discoveryCityCenter(travelLocation);
    if (travelLocation && !travelCenter && query.latitude == null) {
      throw new BadRequestException(
        "Choose a supported travel city or provide its coordinates.",
      );
    }
    const savedCoordinates =
      current.onboardingProfile.latitude != null &&
      current.onboardingProfile.longitude != null
        ? {
            latitude: current.onboardingProfile.latitude,
            longitude: current.onboardingProfile.longitude,
          }
        : undefined;
    const center =
      query.latitude != null && query.longitude != null
        ? { latitude: query.latitude, longitude: query.longitude }
        : travelLocation
          ? travelCenter
          : savedCoordinates;
    const centerLat = center?.latitude;
    const centerLng = center?.longitude;
    if (!center) {
      throw new BadRequestException(
        "Enable location to find people near you, or select a travel city.",
      );
    }
    const radiusKm =
      query.radiusKm ?? current.onboardingProfile.preferredDistanceKm;
    // Nearby-only members see just their radius. Everyone else sees nearby
    // people first, then people further away so the feed is never empty
    // while profiles exist elsewhere.
    const nearbyOnly = current.onboardingProfile.onlyShowPeopleNearby;

    const blockedPeerIds = await SafetyService.blockedPeerIds(
      this.prisma,
      current.id,
    );
    const excludedUserIds = [
      ...new Set([
        ...sentLikes.map(({ toUserId }) => toUserId),
        ...sentPasses.map(({ toUserId }) => toUserId),
        ...blockedPeerIds,
      ]),
    ];

    const candidates = await this.prisma.profile.findMany({
      where: {
        userId: { notIn: [current.id, ...excludedUserIds] },
        completedAt: { not: null },
        showProfile: true,
        photos: { some: {} },
        user: {
          onboardingProfile: { is: { completedAt: { not: null } } },
        },
      },
      select: {
        userId: true,
        bio: true,
        location: true,
        education: true,
        fieldOfStudy: true,
        jobTitle: true,
        company: true,
        heightCm: true,
        zodiac: true,
        languages: true,
        showDistance: true,
        showOnlineStatus: true,
        verificationStatus: true,
        createdAt: true,
        photos: {
          select: { secureUrl: true },
          orderBy: { position: "asc" },
        },
        prompts: {
          select: { question: true, answer: true },
          orderBy: { position: "asc" },
        },
        user: {
          select: {
            id: true,
            username: true,
            lastActiveAt: true,
            onboardingProfile: {
              select: {
                birthDate: true,
                genderIdentity: true,
                interestedIn: true,
                interests: true,
                musicGenres: true,
                favoriteArtists: true,
                latitude: true,
                longitude: true,
              },
            },
          },
        },
      },
      orderBy: { updatedAt: "desc" },
      take: 500,
    });

    const filtered = candidates.flatMap((profile) => {
      const onboarding = profile.user.onboardingProfile;
      if (
        !onboarding?.birthDate ||
        !onboarding.genderIdentity ||
        !onboarding.interestedIn
      )
        return [];
      const age = this.age(onboarding.birthDate, now);
      if (age < (query.minAge ?? 18) || age > (query.maxAge ?? 70)) return [];
      if (
        query.gender &&
        query.gender !== "everyone" &&
        onboarding.genderIdentity !== query.gender
      )
        return [];
      if (
        !this.isInterestedIn(
          onboarding.interestedIn,
          current.onboardingProfile!.genderIdentity!,
        )
      )
        return [];
      if (
        !this.isInterestedIn(
          current.onboardingProfile!.interestedIn!,
          onboarding.genderIdentity,
        )
      )
        return [];
      if (
        (query.onlineOnly || query.mode === "online") &&
        (!profile.showOnlineStatus ||
          !profile.user.lastActiveAt ||
          profile.user.lastActiveAt < onlineAfter)
      )
        return [];
      if (query.verifiedOnly && profile.verificationStatus !== "verified")
        return [];

      const interests = this.profileInterests(
        onboarding.interests,
        onboarding.musicGenres,
        onboarding.favoriteArtists,
      );
      if (
        requestedInterests.length &&
        !interests.some((interest) =>
          requestedInterests.includes(this.normalize(interest)),
        )
      )
        return [];
      const distanceKm =
        centerLat != null &&
        centerLng != null &&
        onboarding.latitude != null &&
        onboarding.longitude != null
          ? this.distanceKm(
              centerLat,
              centerLng,
              onboarding.latitude,
              onboarding.longitude,
            )
          : null;
      const beyondRadius = distanceKm == null || distanceKm > radiusKm;
      if (beyondRadius && nearbyOnly) return [];

      const currentInterests = this.profileInterests(
        current.onboardingProfile!.interests,
        current.onboardingProfile!.musicGenres,
        current.onboardingProfile!.favoriteArtists,
      ).map((interest) => this.normalize(interest));
      const overlap = interests.filter((interest) =>
        currentInterests.includes(this.normalize(interest)),
      ).length;
      const match = currentInterests.length
        ? Math.round((overlap / currentInterests.length) * 100)
        : 0;
      const photos = profile.photos.map((photo) => photo.secureUrl);
      const approximateLatitude =
        onboarding.latitude == null
          ? null
          : Math.round(onboarding.latitude * 100) / 100;
      const approximateLongitude =
        onboarding.longitude == null
          ? null
          : Math.round(onboarding.longitude * 100) / 100;
      return [
        {
          id: profile.userId,
          name: profile.user.username?.trim() || "Just2 member",
          age,
          image: photos[0],
          photos,
          location: profile.location,
          distanceKm:
            !profile.showDistance || distanceKm == null
              ? null
              : Math.round(distanceKm * 10) / 10,
          distance: !profile.showDistance
            ? (profile.location ?? "Distance hidden")
            : distanceKm == null
              ? (profile.location ?? "Location not shared")
              : `${Math.round(distanceKm)} km away`,
          match,
          bio: profile.bio ?? "",
          tags: interests
            .slice(0, 6)
            .map((interest) => interest.replaceAll("_", " ")),
          online:
            profile.showOnlineStatus &&
            profile.user.lastActiveAt != null &&
            profile.user.lastActiveAt >= onlineAfter,
          education:
            [profile.education, profile.fieldOfStudy]
              .filter(Boolean)
              .join(", ") || null,
          fieldOfStudy: profile.fieldOfStudy,
          jobTitle: profile.jobTitle,
          company: profile.company,
          heightCm: profile.heightCm,
          zodiac: profile.zodiac,
          languages: profile.languages,
          prompts: profile.prompts.map(({ question, answer }) => ({
            question,
            answer,
          })),
          latitude: profile.showDistance ? approximateLatitude : null,
          longitude: profile.showDistance ? approximateLongitude : null,
          verified: profile.verificationStatus === "verified",
          beyondRadius,
          createdAt: profile.createdAt,
          sortDistanceKm: distanceKm,
        },
      ];
    });

    type Person = (typeof filtered)[number];
    const byDistance = (a: Person, b: Person) =>
      (a.sortDistanceKm ?? Number.MAX_VALUE) -
      (b.sortDistanceKm ?? Number.MAX_VALUE);
    const byMode =
      query.mode === "nearby"
        ? byDistance
        : query.mode === "new"
          ? (a: Person, b: Person) =>
              b.createdAt.getTime() - a.createdAt.getTime()
          : (a: Person, b: Person) => b.match - a.match;
    // People within the radius always come first, ordered by the tab; people
    // further away follow, nearest first.
    filtered.sort((a, b) =>
      a.beyondRadius !== b.beyondRadius
        ? Number(a.beyondRadius) - Number(b.beyondRadius)
        : a.beyondRadius
          ? byDistance(a, b)
          : byMode(a, b),
    );
    return filtered
      .slice(0, query.limit ?? 60)
      .map(
        ({ createdAt: _createdAt, sortDistanceKm: _distance, ...person }) =>
          person,
      );
  }

  private age(birthDate: Date, now: Date): number {
    let age = now.getUTCFullYear() - birthDate.getUTCFullYear();
    if (
      now.getUTCMonth() < birthDate.getUTCMonth() ||
      (now.getUTCMonth() === birthDate.getUTCMonth() &&
        now.getUTCDate() < birthDate.getUTCDate())
    )
      age--;
    return age;
  }

  private isInterestedIn(preference: string, genderIdentity: string): boolean {
    if (preference === "everyone") return true;
    if (genderIdentity === "man") return preference === "men";
    if (genderIdentity === "woman") return preference === "women";
    return false;
  }

  private profileInterests(
    interests: string[],
    genres: string[],
    artists: string[],
  ): string[] {
    return [...new Set([...interests, ...genres, ...artists])];
  }

  private normalize(value?: string): string {
    return (value ?? "").toLocaleLowerCase().replace(/[^a-z0-9]/g, "");
  }

  private distanceKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const radians = (value: number) => (value * Math.PI) / 180;
    const deltaLat = radians(lat2 - lat1);
    const deltaLon = radians(lon2 - lon1);
    const a =
      Math.sin(deltaLat / 2) ** 2 +
      Math.cos(radians(lat1)) *
        Math.cos(radians(lat2)) *
        Math.sin(deltaLon / 2) ** 2;
    return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
