import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ClerkAuthGuard, ClerkRequest } from "../auth/clerk-auth.guard";
import { UsersService } from "./users.service";
import { UpdateOnboardingDto } from "./dto/update-onboarding.dto";
import { UpdateNameDto } from "./dto/update-name.dto";

@Controller("users")
@UseGuards(ClerkAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get("me")
  getMe(@Req() request: ClerkRequest) {
    return this.users.syncFromClerk(request.auth.userId);
  }

  @Patch("me/onboarding")
  updateOnboarding(
    @Req() request: ClerkRequest,
    @Body() body: UpdateOnboardingDto,
  ) {
    return this.users.updateOnboarding(request.auth.userId, body);
  }

  @Post("me/onboarding/complete")
  completeOnboarding(@Req() request: ClerkRequest) {
    return this.users.completeOnboarding(request.auth.userId);
  }

  @Post("me/activity")
  recordActivity(@Req() request: ClerkRequest) {
    return this.users.recordActivity(request.auth.userId);
  }

  @Patch("me/name")
  updateName(@Req() request: ClerkRequest, @Body() body: UpdateNameDto) {
    return this.users.updateName(request.auth.userId, body);
  }
}
