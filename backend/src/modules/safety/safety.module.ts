import { Module } from "@nestjs/common";
import { ClerkAuthGuard } from "../auth/clerk-auth.guard";
import { SafetyController } from "./safety.controller";
import { SafetyService } from "./safety.service";

@Module({
  controllers: [SafetyController],
  providers: [SafetyService, ClerkAuthGuard],
})
export class SafetyModule {}
