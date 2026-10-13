import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { VibeRoomsController } from "./vibe-rooms.controller";
import { VibeRoomMessagesService } from "./vibe-room-messages.service";
import { VibeRoomsService } from "./vibe-rooms.service";
import { VibeRoomsGateway } from "./vibe-rooms.gateway";
import { VibeGameService } from "./vibe-game.service";
import { VibeRoomVoiceService } from "./vibe-room-voice.service";
import { VoiceNoteStorage } from "../messages/voice-note.storage";

@Module({
  controllers: [VibeRoomsController],
  providers: [
    VibeRoomsService,
    VibeRoomMessagesService,
    VibeRoomsGateway,
    VibeGameService,
    VibeRoomVoiceService,
    VoiceNoteStorage,
    ClerkAuthGuard,
  ],
})
export class VibeRoomsModule {}
