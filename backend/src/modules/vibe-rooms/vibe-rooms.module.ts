import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { VibeRoomsController } from "./vibe-rooms.controller";
import { VibeRoomMessagesService } from "./vibe-room-messages.service";
import { VibeRoomsService } from "./vibe-rooms.service";

@Module({
  controllers: [VibeRoomsController],
  providers: [VibeRoomsService, VibeRoomMessagesService, ClerkAuthGuard],
})
export class VibeRoomsModule {}
