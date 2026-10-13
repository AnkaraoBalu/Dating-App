import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { MessagesModule } from "../messages/messages.module";
import { CallsController } from "./calls.controller";
import { CallsService } from "./calls.service";

@Module({
  imports: [MessagesModule],
  controllers: [CallsController],
  providers: [CallsService, ClerkAuthGuard],
})
export class CallsModule {}
