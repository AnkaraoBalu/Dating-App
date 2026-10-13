import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { v2 as cloudinary, UploadApiResponse } from "cloudinary";

/** Voice messages are short clips; two minutes of AAC is about 1-2 MB. */
export const VOICE_NOTE_MAX_BYTES = 5 * 1024 * 1024;
export const VOICE_NOTE_MAX_DURATION_MS = 2 * 60 * 1000;

export type StoredVoiceNote = {
  url: string;
  publicId: string;
  mimeType: string;
  size: number;
  durationMs: number;
};

/**
 * Validates and stores voice message audio (AAC in an .m4a container, as the
 * app records it) in Cloudinary. Shared by direct and Vibe room chats.
 */
@Injectable()
export class VoiceNoteStorage {
  private readonly logger = new Logger(VoiceNoteStorage.name);

  constructor(config: ConfigService) {
    cloudinary.config({
      cloud_name: config.getOrThrow<string>("CLOUDINARY_CLOUD_NAME"),
      api_key: config.getOrThrow<string>("CLOUDINARY_API_KEY"),
      api_secret: config.getOrThrow<string>("CLOUDINARY_API_SECRET"),
      secure: true,
    });
  }

  /** Throws a 400 unless `file` is a plausible voice clip. */
  assertValid(file: Express.Multer.File | undefined, rawDurationMs: unknown) {
    if (!file || !this.isM4a(file)) {
      throw new BadRequestException(
        "Record a voice message up to 2 minutes long.",
      );
    }
    const durationMs = Number(rawDurationMs);
    if (
      !Number.isFinite(durationMs) ||
      durationMs < 500 ||
      durationMs > VOICE_NOTE_MAX_DURATION_MS + 2000
    ) {
      throw new BadRequestException("Voice messages can be up to 2 minutes.");
    }
    return Math.round(durationMs);
  }

  async upload(
    file: Express.Multer.File,
    folder: string,
    clientDurationMs: number,
  ): Promise<StoredVoiceNote> {
    let uploaded: UploadApiResponse;
    try {
      uploaded = await new Promise<UploadApiResponse>((resolve, reject) => {
        // Cloudinary stores audio under the "video" resource type.
        const stream = cloudinary.uploader.upload_stream(
          { folder, resource_type: "video", overwrite: false },
          (error, result) =>
            error || !result
              ? reject(error ?? new Error("Upload returned no audio"))
              : resolve(result),
        );
        stream.end(file.buffer);
      });
    } catch (error) {
      this.logger.warn(
        `Voice message upload failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new ServiceUnavailableException(
        "Voice message upload failed. Try again.",
      );
    }
    // Prefer the length Cloudinary measured over the one the app reported.
    const measured =
      typeof uploaded.duration === "number"
        ? Math.round(uploaded.duration * 1000)
        : 0;
    return {
      url: uploaded.secure_url,
      publicId: uploaded.public_id,
      mimeType: "audio/mp4",
      size: file.size,
      durationMs: measured > 0 ? measured : clientDurationMs,
    };
  }

  async destroy(publicId: string) {
    await cloudinary.uploader
      .destroy(publicId, { resource_type: "video", invalidate: true })
      .catch(() => undefined);
  }

  private isM4a(file: Express.Multer.File) {
    if (file.size > VOICE_NOTE_MAX_BYTES || file.size < 64) return false;
    // ISO base media file: a box size, then "ftyp".
    return file.buffer.toString("ascii", 4, 8) === "ftyp";
  }
}
