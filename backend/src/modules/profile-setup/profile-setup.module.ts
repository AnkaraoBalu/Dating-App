import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { ProfileSetupController } from "./profile-setup.controller";
import { ProfileSetupService } from "./profile-setup.service";

import { ProfileRepository } from "./profile.repository";
import { ProfileDiscoveryService } from "./profile-discovery.service";
import { ProfilePhotosService } from "./profile-photos.service";
import { ProfileConnectionsService } from "./profile-connections.service";

@Module({
  controllers: [ProfileSetupController],
  providers: [
    ProfileSetupService,
    ProfileRepository,
    ProfileDiscoveryService,
    ProfilePhotosService,
    ProfileConnectionsService,
    ClerkAuthGuard,
  ],
})
export class ProfileSetupModule {}
