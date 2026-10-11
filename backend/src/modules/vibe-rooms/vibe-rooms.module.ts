import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { VibeRoomsController } from "./vibe-rooms.controller";
import { VibeRoomMessagesService } from "./vibe-room-messages.service";
import { VibeRoomsService } from "./vibe-rooms.service";
import { VibeRoomsGateway } from "./vibe-rooms.gateway";

@Module({
  controllers: [VibeRoomsController],
  providers: [
    VibeRoomsService,
    VibeRoomMessagesService,
    VibeRoomsGateway,
    ClerkAuthGuard,
  ],
})
export class VibeRoomsModule {}
