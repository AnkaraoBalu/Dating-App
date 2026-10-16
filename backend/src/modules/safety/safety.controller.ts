import { Body, Controller, Param, Post, Req, UseGuards } from "@nestjs/common";
import { ClerkAuthGuard, ClerkRequest } from "../auth/clerk-auth.guard";
import { ReportUserDto } from "./dto/report-user.dto";
import { SafetyService } from "./safety.service";

@Controller("safety/users")
@UseGuards(ClerkAuthGuard)
export class SafetyController {
  constructor(private readonly safety: SafetyService) {}

  @Post(":userId/block") block(
    @Req() request: ClerkRequest,
    @Param("userId") userId: string,
  ) {
    return this.safety.block(request.auth.userId, userId);
  }

  @Post(":userId/unmatch") unmatch(
    @Req() request: ClerkRequest,
    @Param("userId") userId: string,
  ) {
    return this.safety.unmatch(request.auth.userId, userId);
  }

  @Post(":userId/report") report(
    @Req() request: ClerkRequest,
    @Param("userId") userId: string,
    @Body() body: ReportUserDto,
  ) {
    return this.safety.report(request.auth.userId, userId, body);
  }
}
