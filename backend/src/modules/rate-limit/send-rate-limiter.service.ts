import {
  HttpException,
  HttpStatus,
  Injectable,
  OnModuleDestroy,
} from "@nestjs/common";

export interface RateRule {
  limit: number;
  windowMs: number;
}

/** A short burst allowance plus a sustained per-minute cap. */
export const MESSAGE_RATE_RULES: readonly RateRule[] = [
  { limit: 8, windowMs: 5_000 },
  { limit: 60, windowMs: 60_000 },
];

export class TooManyMessagesException extends HttpException {
  constructor(readonly retryAfterSeconds: number) {
    super(
      {
        statusCode: HttpStatus.TOO_MANY_REQUESTS,
        message: `You're sending messages too fast. Try again in ${retryAfterSeconds} ${
          retryAfterSeconds === 1 ? "second" : "seconds"
        }.`,
        retryAfterSeconds,
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }
}

/**
 * Per-user sliding-window limit for sending messages (chat and Vibe rooms).
 *
 * Kept in memory, so limits are per API instance; move the counters to Redis
 * before running more than one instance.
 */
@Injectable()
export class SendRateLimiter implements OnModuleDestroy {
  rules: readonly RateRule[] = MESSAGE_RATE_RULES;
  now: () => number = () => Date.now();
  private readonly hits = new Map<string, number[]>();
  private readonly sweep = setInterval(() => this.prune(), 60_000);

  constructor() {
    this.sweep.unref?.();
  }

  /**
   * Records one send for `key` (for example `chat:<userId>`), or throws
   * TooManyMessagesException without recording it.
   */
  consume(key: string) {
    const now = this.now();
    const longest = Math.max(...this.rules.map((rule) => rule.windowMs));
    const recent = (this.hits.get(key) ?? []).filter(
      (time) => now - time < longest,
    );
    let retryAfterMs = 0;
    for (const rule of this.rules) {
      const inWindow = recent.filter((time) => now - time < rule.windowMs);
      if (inWindow.length >= rule.limit) {
        // The oldest send in the window has to age out first.
        const wait =
          inWindow[inWindow.length - rule.limit] + rule.windowMs - now;
        retryAfterMs = Math.max(retryAfterMs, wait);
      }
    }
    if (retryAfterMs > 0) {
      this.hits.set(key, recent);
      throw new TooManyMessagesException(Math.ceil(retryAfterMs / 1000));
    }
    recent.push(now);
    this.hits.set(key, recent);
  }

  private prune() {
    const now = this.now();
    const longest = Math.max(...this.rules.map((rule) => rule.windowMs));
    for (const [key, times] of this.hits) {
      if (times.every((time) => now - time >= longest)) this.hits.delete(key);
    }
  }

  onModuleDestroy() {
    clearInterval(this.sweep);
  }
}
