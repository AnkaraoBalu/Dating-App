import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ClerkAuthGuard, ClerkRequest } from "../auth/clerk-auth.guard";
import {
  CreateVibeRoomDto,
  CreateVibeRoomMessageDto,
  CreateVibeGameDto,
  ListVibeRoomsQueryDto,
  ListVibeRoomMessagesQueryDto,
  SetVibeRoomSavedDto,
  SubmitVibeGameAnswerDto,
  UpdateVibeRoomDto,
} from "./dto/vibe-room.dto";
import { VibeRoomMessagesService } from "./vibe-room-messages.service";
import { VibeRoomsService } from "./vibe-rooms.service";
import { VibeRoomsGateway } from "./vibe-rooms.gateway";
import { SendRateLimiter } from "../rate-limit/send-rate-limiter.service";
import { NotificationsService } from "../notifications/notifications.service";
import { RealtimeService } from "../realtime/realtime.service";
import { VibeGameService } from "./vibe-game.service";
import { VibeRoomVoiceService } from "./vibe-room-voice.service";
import { VOICE_NOTE_MAX_BYTES } from "../messages/voice-note.storage";

@Controller("vibe-rooms")
@UseGuards(ClerkAuthGuard)
export class VibeRoomsController {
  constructor(
    private readonly rooms: VibeRoomsService,
    private readonly messages: VibeRoomMessagesService,
    private readonly gateway: VibeRoomsGateway,
    private readonly limiter: SendRateLimiter,
    private readonly notifications: NotificationsService,
    private readonly realtime: RealtimeService,
    private readonly games: VibeGameService,
    private readonly voice: VibeRoomVoiceService,
  ) {}

  @Get()
  list(@Req() request: ClerkRequest, @Query() query: ListVibeRoomsQueryDto) {
    return this.rooms.list(request.auth.userId, query);
  }

  /** Rooms I'm in, as group chats for the Chat tab. */
  @Get("chats")
  chats(@Req() request: ClerkRequest) {
    return this.rooms.chats(request.auth.userId);
  }

  @Post(":roomId/read")
  markRead(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    return this.rooms.markRead(request.auth.userId, roomId);
  }

  @Post()
  create(@Req() request: ClerkRequest, @Body() body: CreateVibeRoomDto) {
    return this.rooms.create(request.auth.userId, body);
  }

  @Patch(":roomId/saved")
  setSaved(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Body() body: SetVibeRoomSavedDto,
  ) {
    return this.rooms.setSaved(request.auth.userId, roomId, body.saved);
  }

  @Post(":roomId/voice-token")
  voiceToken(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    return this.voice.createJoinToken(request.auth.userId, roomId);
  }

  /** Host-only: mutes someone's microphone in the room's voice call. */
  @Post(":roomId/voice/participants/:participantId/mute")
  muteVoiceParticipant(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Param("participantId") participantId: string,
  ) {
    return this.voice.muteParticipant(
      request.auth.userId,
      roomId,
      participantId,
    );
  }

  @Post(":roomId/join")
  async join(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    const joined = await this.rooms.joinWithDetails(
      request.auth.userId,
      roomId,
    );
    if (joined.newlyJoined) {
      // Best effort, after the join is saved: a "… joined the room" line in
      // the chat for everyone, a refreshed Chat list, and a push to the host.
      try {
        const line = await this.messages.recordJoin(joined.userId, roomId);
        await this.gateway.broadcastMessage(roomId, line);
      } catch {
        // The join itself succeeded; the history line is a nicety.
      }
      void this.refreshInboxes(roomId);
      if (joined.hostUserId && joined.hostUserId !== joined.userId) {
        void this.notifications.vibeRoomJoined(joined.hostUserId, {
          roomId,
          title: joined.title,
          joinerId: joined.userId,
        });
      }
    }
    return joined.room;
  }

  @Delete(":roomId/membership")
  async leave(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    const room = await this.rooms.leave(request.auth.userId, roomId);
    const gameIds = await this.games.leaveRoom(request.auth.userId, roomId);
    for (const sessionId of gameIds) {
      await this.gateway.broadcastGame(roomId, sessionId, "participant_left");
    }
    const userId = await this.messages.databaseUserId(request.auth.userId);
    this.gateway.removeMember(roomId, userId);
    void this.voice.removeParticipant(roomId, userId);
    return room;
  }

  /** Host-only: edits the room's details or takes it live. */
  @Patch(":roomId")
  update(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Body() body: UpdateVibeRoomDto,
  ) {
    return this.rooms.update(request.auth.userId, roomId, body);
  }

  /** Host-only: deletes the room for everyone. */
  @Delete(":roomId")
  async remove(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    const { memberIds, mediaPublicIds } = await this.rooms.delete(
      request.auth.userId,
      roomId,
    );
    // The delete is saved; the rest is best-effort cleanup.
    this.gateway.roomDeleted(roomId);
    void this.voice.closeRoom(roomId);
    void this.messages.destroyMedia(mediaPublicIds).catch(() => undefined);
    for (const memberId of memberIds) {
      this.realtime.notifyUser(memberId, "inbox:changed", { roomId });
    }
    return { deleted: true };
  }

  @Get(":roomId/messages")
  listMessages(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Query() query: ListVibeRoomMessagesQueryDto,
  ) {
    return this.messages.list(request.auth.userId, roomId, query);
  }

  @Post(":roomId/messages")
  async sendMessage(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Body() body: CreateVibeRoomMessageDto,
  ) {
    const userId = await this.messages.databaseUserId(request.auth.userId);
    this.limiter.consume(`vibe:${userId}`);
    const message = await this.messages.send(request.auth.userId, roomId, body);
    // Saved first; live delivery to the room is best effort.
    const viewers = await this.gateway.broadcastMessage(roomId, message);
    // Everyone else in the room gets a push, without delaying the response,
    // and every member's Chat list moves this room to the top.
    void this.notifyAway(roomId, userId, viewers, message.text);
    void this.refreshInboxes(roomId);
    return message;
  }

  @Post(":roomId/messages/voice")
  @UseInterceptors(
    FileInterceptor("file", {
      limits: { fileSize: VOICE_NOTE_MAX_BYTES, files: 1 },
    }),
  )
  async sendVoiceMessage(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Body("clientMessageId") clientMessageId: string,
    @Body("durationMs") durationMs: string | undefined,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const userId = await this.messages.databaseUserId(request.auth.userId);
    this.limiter.consume(`vibe:${userId}`);
    const message = await this.messages.sendVoice(
      request.auth.userId,
      roomId,
      clientMessageId,
      durationMs,
      file,
    );
    const viewers = await this.gateway.broadcastMessage(roomId, message);
    void this.notifyAway(roomId, userId, viewers, "", "voice");
    void this.refreshInboxes(roomId);
    return message;
  }

  @Get(":roomId/games/active")
  activeGame(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    return this.games.active(request.auth.userId, roomId);
  }

  @Post(":roomId/games")
  async createGame(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Body() body: CreateVibeGameDto,
  ) {
    const state = await this.games.create(
      request.auth.userId,
      roomId,
      body.gameType,
      body.setup,
    );
    const viewers = await this.gateway.broadcastGame(
      roomId,
      state.id,
      "created",
      state.title,
    );
    void this.notifyGameAway(roomId, state.title, state.hostId, viewers, false);
    return state;
  }

  @Get(":roomId/games/:sessionId")
  async gameState(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Param("sessionId") sessionId: string,
  ) {
    const state = await this.games.stateFor(request.auth.userId, sessionId);
    if (state.roomId !== roomId)
      throw new NotFoundException("Game session not found.");
    return state;
  }

  @Post(":roomId/games/:sessionId/join")
  async joinGame(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Param("sessionId") sessionId: string,
  ) {
    await this.games.assertSessionInRoom(sessionId, roomId);
    const state = await this.games.join(request.auth.userId, sessionId);
    await this.gateway.broadcastGame(
      roomId,
      sessionId,
      "participant_joined",
      state.title,
    );
    return state;
  }

  @Post(":roomId/games/:sessionId/start")
  async startGame(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Param("sessionId") sessionId: string,
  ) {
    await this.games.assertSessionInRoom(sessionId, roomId);
    const state = await this.games.start(request.auth.userId, sessionId);
    const viewers = await this.gateway.broadcastGame(
      roomId,
      sessionId,
      "started",
      state.title,
    );
    void this.notifyGameAway(roomId, state.title, state.hostId, viewers, true);
    return state;
  }

  @Post(":roomId/games/:sessionId/answers")
  async answerGame(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Param("sessionId") sessionId: string,
    @Body() body: SubmitVibeGameAnswerDto,
  ) {
    await this.games.assertSessionInRoom(sessionId, roomId);
    const state = await this.games.answer(
      request.auth.userId,
      sessionId,
      body.questionIndex,
      body.choiceIndex,
    );
    this.gateway.broadcastGameProgress(roomId, sessionId, state.title);
    return state;
  }

  @Post(":roomId/games/:sessionId/leave")
  async leaveGame(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Param("sessionId") sessionId: string,
  ) {
    await this.games.assertSessionInRoom(sessionId, roomId);
    const state = await this.games.leave(request.auth.userId, sessionId);
    await this.gateway.broadcastGame(
      roomId,
      sessionId,
      "participant_left",
      state.title,
    );
    return state;
  }

  /** Tells every member's open app sessions to reload their Chat list. */
  private async refreshInboxes(roomId: string) {
    try {
      for (const memberId of await this.messages.activeMemberIds(roomId)) {
        this.realtime.notifyUser(memberId, "inbox:changed", { roomId });
      }
    } catch {
      // Best effort: the list also refreshes when the Chat tab opens.
    }
  }

  /** Push-notifies active members who didn't get the message live. */
  private async notifyAway(
    roomId: string,
    senderId: string,
    viewers: Set<string>,
    text: string,
    type = "text",
  ) {
    try {
      const { title, userIds } = await this.messages.pushRecipients(roomId, [
        senderId,
        ...viewers,
      ]);
      await this.notifications.vibeRoomMessage(userIds, {
        roomId,
        title,
        senderId,
        text,
        type,
      });
    } catch {
      // Notifications are best effort; the message is already delivered.
    }
  }

  private async notifyGameAway(
    roomId: string,
    gameTitle: string,
    hostId: string,
    viewers: Set<string>,
    started: boolean,
  ) {
    try {
      const { title, userIds } = await this.messages.pushRecipients(roomId, [
        hostId,
        ...viewers,
      ]);
      await this.notifications.vibeRoomMessage(userIds, {
        roomId,
        title,
        senderId: hostId,
        text: started
          ? `🎮 ${gameTitle} is live. Open the room and tap Games to join.`
          : `🎮 A ${gameTitle} game is waiting for players. Open the room and tap Games to join.`,
      });
    } catch {
      // The game is already saved and broadcast to connected room members.
    }
  }
}
