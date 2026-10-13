import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { readFileSync } from "node:fs";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging, type Messaging } from "firebase-admin/messaging";

export interface PushMessage {
  title: string;
  body: string;
  /** Read by the app to decide which screen a tap opens. */
  data: Record<string, string>;
  /** Groups notifications, e.g. one per conversation. */
  group?: string;
}

/** Firebase error codes meaning the token will never work again. */
const DEAD_TOKEN_ERRORS = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

const APP_NAME = "just2-push";

/**
 * Sends Firebase Cloud Messaging pushes. Disabled (with one warning) until
 * FIREBASE_SERVICE_ACCOUNT_PATH points at the project's service account key.
 */
@Injectable()
export class FirebasePushSender {
  private readonly logger = new Logger(FirebasePushSender.name);
  /** undefined = not initialised yet; null = push is not configured. */
  private messaging?: Messaging | null;

  constructor(private readonly config: ConfigService) {}

  private client(): Messaging | null {
    if (this.messaging !== undefined) return this.messaging;
    const keyPath = this.config.get<string>("FIREBASE_SERVICE_ACCOUNT_PATH");
    if (!keyPath) {
      this.logger.warn(
        "Push notifications are off: set FIREBASE_SERVICE_ACCOUNT_PATH.",
      );
      this.messaging = null;
      return null;
    }
    const credentials = JSON.parse(readFileSync(keyPath, "utf8"));
    const app =
      getApps().find((existing) => existing.name === APP_NAME) ??
      initializeApp({ credential: cert(credentials) }, APP_NAME);
    this.messaging = getMessaging(app);
    return this.messaging;
  }

  /** Sends to every token and returns the tokens Firebase rejected for good. */
  async send(tokens: string[], message: PushMessage): Promise<string[]> {
    const messaging = this.client();
    if (!messaging || tokens.length === 0) return [];
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          tag: message.group,
          // High-importance channel created by the app, so Android shows a
          // banner at the top (see SystemNotifications in the Flutter app).
          channelId: "just2_alerts",
        },
      },
      apns: {
        payload: { aps: { sound: "default", threadId: message.group } },
      },
    });
    return response.responses.flatMap((result, index) =>
      !result.success && DEAD_TOKEN_ERRORS.has(result.error?.code ?? "")
        ? [tokens[index]]
        : [],
    );
  }
}
