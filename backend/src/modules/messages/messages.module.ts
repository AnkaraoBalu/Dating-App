import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { MessagesController } from "./messages.controller";
import { MessagesGateway } from "./messages.gateway";
import { MessagesService } from "./messages.service";
import { MessageMediaService } from "./message-media.service";
import { ConversationsService } from "./conversations.service";

@Module({
  controllers: [MessagesController],
  providers: [
    MessagesService,
    ConversationsService,
    MessageMediaService,
    MessagesGateway,
    ClerkAuthGuard,
  ],
})
export class MessagesModule {}
