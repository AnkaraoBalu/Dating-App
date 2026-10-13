import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  AccessToken,
  RoomServiceClient,
  TrackSource,
} from "livekit-server-sdk";

export type LiveKitJoin = {
  serverUrl: string;
  participantToken: string;
};

/**
 * LiveKit audio for Vibe room voice and one-to-one calls. The API secret
 * stays here; the app only receives short-lived, single-room join tokens.
 */
@Injectable()
export class LiveKitService {
  private readonly logger = new Logger(LiveKitService.name);
  private roomService?: RoomServiceClient;

  constructor(private readonly config: ConfigService) {}

  get configured() {
    return this.settings() !== null;
  }

  /** A token that can join `room` and publish only microphone audio. */
  async joinToken(options: {
    room: string;
    identity: string;
    name: string;
    metadata?: object;
  }): Promise<LiveKitJoin> {
    const settings = this.requireSettings();
    const token = new AccessToken(settings.apiKey, settings.apiSecret, {
      identity: options.identity,
      name: options.name,
      ttl: "1h",
    });
    if (options.metadata) token.metadata = JSON.stringify(options.metadata);
    token.addGrant({
      roomJoin: true,
      room: options.room,
      canPublish: true,
      canSubscribe: true,
      canPublishSources: [TrackSource.MICROPHONE],
    });
    return {
      serverUrl: settings.serverUrl,
      participantToken: await token.toJwt(),
    };
  }

  /** Server-side room controls; throws 503 when LiveKit is not configured. */
  rooms() {
    if (this.roomService) return this.roomService;
    const settings = this.requireSettings();
    // The room service API speaks HTTPS on the same host as the signal URL.
    this.roomService = new RoomServiceClient(
      settings.serverUrl.replace(/^ws/i, "http"),
      settings.apiKey,
      settings.apiSecret,
    );
    return this.roomService;
  }

  /** Best effort: drops someone from a room they may not be in. */
  async removeParticipant(room: string, identity: string) {
    if (!this.configured) return;
    try {
      await this.rooms().removeParticipant(room, identity);
    } catch (error) {
      // Usually "participant not found": they were not connected.
      this.logger.debug(`Removal skipped for ${identity} in ${room}: ${error}`);
    }
  }

  /** Best effort: disconnects everyone and closes the room. */
  async deleteRoom(room: string) {
    if (!this.configured) return;
    try {
      await this.rooms().deleteRoom(room);
    } catch (error) {
      this.logger.debug(`Room close skipped for ${room}: ${error}`);
    }
  }

  /** How many people are connected; null when it cannot be checked. */
  async participantCount(room: string): Promise<number | null> {
    if (!this.configured) return null;
    try {
      return (await this.rooms().listParticipants(room)).length;
    } catch {
      return null;
    }
  }

  private requireSettings() {
    const settings = this.settings();
    if (!settings) {
      throw new ServiceUnavailableException("Voice is not configured yet.");
    }
    return settings;
  }

  private settings() {
    const serverUrl = this.config.get<string>("LIVEKIT_URL");
    const apiKey = this.config.get<string>("LIVEKIT_API_KEY");
    const apiSecret = this.config.get<string>("LIVEKIT_API_SECRET");
    if (!serverUrl || !apiKey || !apiSecret) return null;
    return { serverUrl: normalizeServerUrl(serverUrl), apiKey, apiSecret };
  }
}

function normalizeServerUrl(value: string) {
  const trimmed = value.trim().replace(/\/$/, "");
  if (/^wss?:\/\//i.test(trimmed)) return trimmed;
  if (/^https?:\/\//i.test(trimmed)) return trimmed.replace(/^http/i, "ws");
  return `wss://${trimmed}`;
}
