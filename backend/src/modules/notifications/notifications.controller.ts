import { Body, Controller, Delete, Post, Req, UseGuards } from "@nestjs/common";
import { ClerkAuthGuard, type ClerkRequest } from "../auth/clerk-auth.guard";
import {
  RegisterPushDeviceDto,
  RemovePushDeviceDto,
} from "./dto/push-device.dto";
import { NotificationsService } from "./notifications.service";

@Controller("notifications")
@UseGuards(ClerkAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  /** Called by the app at sign-in and whenever Firebase rotates the token. */
  @Post("devices")
  register(@Req() request: ClerkRequest, @Body() body: RegisterPushDeviceDto) {
    return this.notifications.registerDevice(
      request.auth.userId,
      body.token,
      body.platform,
    );
  }

  /** Called by the app on log out, so the phone stops getting this account's pushes. */
  @Delete("devices")
  remove(@Req() request: ClerkRequest, @Body() body: RemovePushDeviceDto) {
    return this.notifications.removeDevice(request.auth.userId, body.token);
  }
}
