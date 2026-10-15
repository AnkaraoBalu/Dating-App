import {
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PrismaService } from "../../database/prisma.service";
import {
  createDemoSessionToken,
  demoAuthSecret,
  DEMO_USER_PREFIX,
  demoSessionLifetimeSeconds,
} from "./demo-session";

function usernameSuffix(username: string): string {
  return username
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_|_$/g, "");
}

@Injectable()
export class DemoAuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async listUsers() {
    this.assertEnabled();
    const users = await this.prisma.user.findMany({
      where: {
        clerkUserId: { startsWith: DEMO_USER_PREFIX },
        onboardingProfile: { is: { completedAt: { not: null } } },
        profile: { is: { completedAt: { not: null } } },
      },
      select: {
        username: true,
        onboardingProfile: { select: { genderIdentity: true } },
      },
      orderBy: { username: "asc" },
    });
    return {
      users: users.flatMap((user) =>
        user.username
          ? [
              {
                username: user.username,
                gender: user.onboardingProfile?.genderIdentity,
              },
            ]
          : [],
      ),
    };
  }

  async login(username: unknown) {
    this.assertEnabled();
    if (typeof username !== "string" || !username.trim()) {
      throw new NotFoundException("Choose a demo username.");
    }
    const clerkUserId = `${DEMO_USER_PREFIX}${usernameSuffix(username.trim())}`;
    const user = await this.prisma.user.findFirst({
      where: {
        clerkUserId,
        onboardingProfile: { is: { completedAt: { not: null } } },
        profile: { is: { completedAt: { not: null } } },
      },
      select: {
        clerkUserId: true,
        username: true,
        onboardingProfile: { select: { genderIdentity: true } },
      },
    });
    if (!user)
      throw new NotFoundException(
        "Demo user not found. Seed demo profiles first.",
      );

    const secret = this.config.getOrThrow<string>("DEMO_AUTH_SECRET");
    return {
      accessToken: createDemoSessionToken(user.clerkUserId, secret),
      expiresIn: demoSessionLifetimeSeconds,
      user: {
        username: user.username,
        gender: user.onboardingProfile?.genderIdentity,
      },
    };
  }

  private assertEnabled() {
    if (!demoAuthSecret(this.config)) {
      throw new ServiceUnavailableException(
        "Demo sign-in is not enabled for this server.",
      );
    }
  }
}
