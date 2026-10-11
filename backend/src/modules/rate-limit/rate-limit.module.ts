import { Global, Module } from "@nestjs/common";
import { SendRateLimiter } from "./send-rate-limiter.service";

@Global()
@Module({
  providers: [SendRateLimiter],
  exports: [SendRateLimiter],
})
export class RateLimitModule {}
