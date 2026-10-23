import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import type { Prisma } from "@prisma/client";
import { PrismaService } from "../../database/prisma.service";
import { DiscoverProfilesQueryDto } from "./dto/discover-profiles.dto";
import { discoveryTrendingScore } from "./discovery-trending";
import { mixDiscoveryExploration } from "./discovery-exploration";
import { discoveryCityCenter } from "./discovery-location";
import {
  discoveryInterestWeights,
  normalizeDiscoveryInterest,
  sharedInterestScore,
} from "./discovery-affinity";
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
        select: { toUserId: true, createdAt: true },
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
    const currentInterestWeights = discoveryInterestWeights(
      current.onboardingProfile,
    );
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
        ...(query.includeStatus
          ? []
          : sentLikes.map(({ toUserId }) => toUserId)),
        ...(query.includeStatus || query.replayBefore
          ? []
          : sentPasses.map(({ toUserId }) => toUserId)),
        ...blockedPeerIds,
      ]),
    ];

    const candidateQuery = {
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
      // Unique immutable key keeps batch boundaries stable as profiles update.
      orderBy: { userId: "asc" },
      take: 500,
    } satisfies Prisma.ProfileFindManyArgs;
    let batch = await this.prisma.profile.findMany(candidateQuery);
    const candidates = [...batch];
    while (batch.length === candidateQuery.take) {
      const afterUserId = batch[batch.length - 1].userId;
      batch = await this.prisma.profile.findMany({
        ...candidateQuery,
        where: {
          ...candidateQuery.where,
          userId: { ...candidateQuery.where.userId, gt: afterUserId },
        },
      });
      candidates.push(...batch);
    }

    const recentLikeCounts = new Map<string, number>();
    if (query.mode === "trending" && candidates.length) {
      const counts = await this.prisma.profileLike.groupBy({
        by: ["toUserId"],
        where: {
          toUserId: { in: candidates.map((profile) => profile.userId) },
          fromUserId: { notIn: [current.id, ...blockedPeerIds] },
          createdAt: { gte: new Date(now.getTime() - 7 * 86_400_000) },
        },
        _count: { _all: true },
      });
      for (const count of counts)
        recentLikeCounts.set(count.toUserId, count._count._all);
    }

    const likedIds = new Set(sentLikes.map(({ toUserId }) => toUserId));
    const passedAt = new Map(
      sentPasses.map((pass) => [pass.toUserId, pass.createdAt]),
    );
    const replayBefore = query.replayBefore
      ? new Date(query.replayBefore).getTime()
      : null;
    if (replayBefore != null && replayBefore > now.getTime()) {
      throw new BadRequestException("Replay time must not be in the future.");
    }
    let replayAvailable = false;
    const swipedIds = new Set([
      ...sentLikes.map(({ toUserId }) => toUserId),
      ...sentPasses.map(({ toUserId }) => toUserId),
    ]);
    let distanceExcluded = 0;
    let filtersExcluded = 0;
    let swipedEligible = 0;
    const filtered = candidates.flatMap((profile) => {
      const onboarding = profile.user.onboardingProfile;
      if (
        !onboarding?.birthDate ||
        !onboarding.genderIdentity ||
        !onboarding.interestedIn
      )
        return [];
      const age = this.age(onboarding.birthDate, now);
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
      if (age < (query.minAge ?? 18) || age > (query.maxAge ?? 70)) {
        if (!swipedIds.has(profile.userId)) filtersExcluded++;
        return [];
      }
      if (
        query.gender &&
        query.gender !== "everyone" &&
        onboarding.genderIdentity !== query.gender
      ) {
        if (!swipedIds.has(profile.userId)) filtersExcluded++;
        return [];
      }
      if (
        (query.onlineOnly || query.mode === "online") &&
        (!profile.showOnlineStatus ||
          !profile.user.lastActiveAt ||
          profile.user.lastActiveAt < onlineAfter)
      ) {
        if (!swipedIds.has(profile.userId)) filtersExcluded++;
        return [];
      }
      if (query.verifiedOnly && profile.verificationStatus !== "verified") {
        if (!swipedIds.has(profile.userId)) filtersExcluded++;
        return [];
      }

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
      ) {
        if (!swipedIds.has(profile.userId)) filtersExcluded++;
        return [];
      }
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
      if (beyondRadius && nearbyOnly) {
        if (!swipedIds.has(profile.userId) && distanceKm != null)
          distanceExcluded++;
        return [];
      }
      const isPassed = passedAt.has(profile.userId);
      if (likedIds.has(profile.userId)) {
        swipedEligible++;
        return [];
      }
      if (isPassed) {
        swipedEligible++;
        replayAvailable = true;
        const passTime = passedAt.get(profile.userId)?.getTime();
        if (
          replayBefore == null ||
          passTime == null ||
          passTime >= replayBefore
        )
          return [];
      }

      const match = sharedInterestScore(
        currentInterestWeights,
        discoveryInterestWeights(onboarding),
      );
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
          replayed: isPassed,
          passedAt: passedAt.get(profile.userId)?.getTime() ?? 0,
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
          trendingScore:
            query.mode === "trending"
              ? discoveryTrendingScore({
                  recentLikes: recentLikeCounts.get(profile.userId) ?? 0,
                  lastActiveAt: profile.user.lastActiveAt,
                  createdAt: profile.createdAt,
                  now,
                })
              : 0,
        },
      ];
    });

    type Person = (typeof filtered)[number];
    const byDistance = (a: Person, b: Person) =>
      (a.sortDistanceKm ?? Number.MAX_VALUE) -
      (b.sortDistanceKm ?? Number.MAX_VALUE);
    const byMode =
      query.mode === "nearby"
        ? (a: Person, b: Person) => byDistance(a, b) || a.id.localeCompare(b.id)
        : query.mode === "trending"
          ? (a: Person, b: Person) =>
              b.trendingScore - a.trendingScore ||
              byDistance(a, b) ||
              a.id.localeCompare(b.id)
          : query.mode === "new"
            ? (a: Person, b: Person) =>
                b.createdAt.getTime() - a.createdAt.getTime() ||
                a.id.localeCompare(b.id)
            : (a: Person, b: Person) =>
                b.match - a.match ||
                byDistance(a, b) ||
                a.id.localeCompare(b.id);
    // People within the radius always come first, ordered by the tab; people
    // further away follow, nearest first.
    filtered.sort((a, b) =>
      a.replayed !== b.replayed
        ? Number(a.replayed) - Number(b.replayed)
        : a.replayed
          ? a.passedAt - b.passedAt || a.id.localeCompare(b.id)
          : a.beyondRadius !== b.beyondRadius
            ? Number(a.beyondRadius) - Number(b.beyondRadius)
            : a.beyondRadius
              ? byDistance(a, b) || a.id.localeCompare(b.id)
              : byMode(a, b),
    );
    // A replay batch is returned only when no unseen eligible cards remain.
    const unseen = filtered.filter((person) => !person.replayed);
    let ranked = unseen.length ? unseen : filtered;
    if (unseen.length && (query.mode == null || query.mode === "for_you")) {
      // Preserve the distance boundary and the oldest-first replay order.
      const nearby = unseen.filter((person) => !person.beyondRadius);
      const furtherAway = unseen.filter((person) => person.beyondRadius);
      const seed = `${current.id}:${now.toISOString().slice(0, 10)}`;
      ranked = [...mixDiscoveryExploration(nearby, seed), ...furtherAway];
    }
    const people = ranked
      .slice(0, query.limit ?? 60)
      .map(
        ({
          trendingScore: _trendingScore,
          createdAt: _createdAt,
          sortDistanceKm: _distance,
          passedAt: _passedAt,
          replayed: _replayed,
          ...person
        }) => person,
      );
    if (!query.includeStatus) return people;
    const emptyReason = people.length
      ? null
      : distanceExcluded > 0
        ? "distance"
        : filtersExcluded > 0
          ? "filters"
          : swipedEligible > 0
            ? "exhausted"
            : "no_profiles";
    return {
      people,
      emptyReason,
      replayBefore: replayAvailable ? now.toISOString() : null,
    };
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
    return normalizeDiscoveryInterest(value ?? "");
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
