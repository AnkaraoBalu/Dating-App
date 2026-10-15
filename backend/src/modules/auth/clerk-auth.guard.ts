import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { verifyToken } from "@clerk/backend";
import type { Request } from "express";
import {
  demoAuthSecret,
  verifyDemoSessionToken,
} from "../demo-auth/demo-session";

export type ClerkRequest = Request & {
  auth: { userId: string };
};

@Injectable()
export class ClerkAuthGuard implements CanActivate {
  private readonly logger = new Logger(ClerkAuthGuard.name);

  constructor(private readonly config: ConfigService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<ClerkRequest>();
    const authorization = request.headers.authorization;
    const token = authorization?.startsWith("Bearer ")
      ? authorization.slice("Bearer ".length)
      : undefined;

    if (!token) {
      this.logger.warn(
        `Missing bearer token for ${request.method} ${request.path}`,
      );
      throw new UnauthorizedException("Bearer token required");
    }

    const demoSecret = demoAuthSecret(this.config);
    if (demoSecret) {
      const demoUserId = verifyDemoSessionToken(token, demoSecret);
      if (demoUserId) {
        request.auth = { userId: demoUserId };
        return true;
      }
    }

    try {
      const payload = await verifyToken(token, {
        secretKey: this.config.getOrThrow<string>("CLERK_SECRET_KEY"),
      });
      if (!payload.sub) throw new UnauthorizedException("Invalid Clerk token");
      request.auth = { userId: payload.sub };
      this.logger.log(
        `Authenticated Clerk user ${payload.sub} for ${request.method} ${request.path}`,
      );
      return true;
    } catch (error) {
      const reason =
        error instanceof Error ? error.message : "Unknown token error";
      this.logger.warn(
        `Clerk token rejected for ${request.method} ${request.path}: ${reason}`,
      );
      throw new UnauthorizedException("Invalid or expired Clerk token");
    }
  }
}
