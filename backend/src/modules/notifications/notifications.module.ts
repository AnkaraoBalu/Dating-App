import { Global, Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { FirebasePushSender } from "./firebase-push.sender";
import { NotificationsController } from "./notifications.controller";
import { NotificationsService } from "./notifications.service";

/** Push notifications (Firebase Cloud Messaging). Global so any feature can notify. */
@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, FirebasePushSender, ClerkAuthGuard],
  exports: [NotificationsService],
})
export class NotificationsModule {}
