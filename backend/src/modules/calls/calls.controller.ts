import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import { IsNotEmpty, IsString, MaxLength } from "class-validator";
import { ClerkAuthGuard, type ClerkRequest } from "../auth/clerk-auth.guard";
import { CallsService } from "./calls.service";

class StartCallDto {
  @IsString() @IsNotEmpty() @MaxLength(100) conversationId!: string;
}

/**
 * One-to-one voice calls. Starting or answering returns the LiveKit
 * `serverUrl` and `participantToken` for that call's audio room.
 */
@Controller("calls")
@UseGuards(ClerkAuthGuard)
export class CallsController {
  constructor(private readonly calls: CallsService) {}

  @Post()
  start(@Req() request: ClerkRequest, @Body() body: StartCallDto) {
    return this.calls.start(request.auth.userId, body.conversationId);
  }

  @Get(":callId")
  get(@Req() request: ClerkRequest, @Param("callId") callId: string) {
    return this.calls.get(request.auth.userId, callId);
  }

  @Post(":callId/accept")
  accept(@Req() request: ClerkRequest, @Param("callId") callId: string) {
    return this.calls.accept(request.auth.userId, callId);
  }

  @Post(":callId/decline")
  decline(@Req() request: ClerkRequest, @Param("callId") callId: string) {
    return this.calls.decline(request.auth.userId, callId);
  }

  @Post(":callId/end")
  end(@Req() request: ClerkRequest, @Param("callId") callId: string) {
    return this.calls.end(request.auth.userId, callId);
  }
}
