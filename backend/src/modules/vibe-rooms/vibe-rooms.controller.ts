import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ClerkAuthGuard, ClerkRequest } from "../auth/clerk-auth.guard";
import {
  CreateVibeRoomDto,
  CreateVibeRoomMessageDto,
  ListVibeRoomsQueryDto,
  ListVibeRoomMessagesQueryDto,
  SetVibeRoomSavedDto,
} from "./dto/vibe-room.dto";
import { VibeRoomMessagesService } from "./vibe-room-messages.service";
import { VibeRoomsService } from "./vibe-rooms.service";

@Controller("vibe-rooms")
@UseGuards(ClerkAuthGuard)
export class VibeRoomsController {
  constructor(
    private readonly rooms: VibeRoomsService,
    private readonly messages: VibeRoomMessagesService,
  ) {}

  @Get()
  list(@Req() request: ClerkRequest, @Query() query: ListVibeRoomsQueryDto) {
    return this.rooms.list(request.auth.userId, query);
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

  @Post(":roomId/join")
  join(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    return this.rooms.join(request.auth.userId, roomId);
  }

  @Delete(":roomId/membership")
  leave(@Req() request: ClerkRequest, @Param("roomId") roomId: string) {
    return this.rooms.leave(request.auth.userId, roomId);
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
  sendMessage(
    @Req() request: ClerkRequest,
    @Param("roomId") roomId: string,
    @Body() body: CreateVibeRoomMessageDto,
  ) {
    return this.messages.send(request.auth.userId, roomId, body);
  }
}
