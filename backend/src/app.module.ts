import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { validateEnvironment } from "./config/env.validation";
import { HealthModule } from "./modules/health/health.module";
import { DatabaseModule } from "./database/database.module";
import { UsersModule } from "./modules/users/users.module";
import { ProfileSetupModule } from "./modules/profile-setup/profile-setup.module";
import { MessagesModule } from "./modules/messages/messages.module";
import { VibeRoomsModule } from "./modules/vibe-rooms/vibe-rooms.module";
import { AuthModule } from "./modules/demo-auth/auth.module";
import { RealtimeModule } from "./modules/realtime/realtime.module";
import { RateLimitModule } from "./modules/rate-limit/rate-limit.module";
import { NotificationsModule } from "./modules/notifications/notifications.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnvironment }),
    HealthModule,
    AuthModule,
    DatabaseModule,
    RealtimeModule,
    RateLimitModule,
    NotificationsModule,
    UsersModule,
    ProfileSetupModule,
    MessagesModule,
    VibeRoomsModule,
  ],
})
export class AppModule {}
