import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { v2 as cloudinary, UploadApiResponse } from "cloudinary";
import { PrismaService } from "../../database/prisma.service";
import { MessagesService } from "./messages.service";
import { VoiceNoteStorage } from "./voice-note.storage";

@Injectable()
export class MessageMediaService {
  private readonly logger = new Logger(MessageMediaService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly messages: MessagesService,
    private readonly voiceNotes: VoiceNoteStorage,
    config: ConfigService,
  ) {
    cloudinary.config({
      cloud_name: config.getOrThrow<string>("CLOUDINARY_CLOUD_NAME"),
      api_key: config.getOrThrow<string>("CLOUDINARY_API_KEY"),
      api_secret: config.getOrThrow<string>("CLOUDINARY_API_SECRET"),
      secure: true,
    });
  }

  async deleteExpiredMedia(publicIds: string[]) {
    for (const publicId of publicIds) {
      try {
        let result = await cloudinary.uploader.destroy(publicId, {
          invalidate: true,
        });
        if (result.result === "not found") {
          // Voice messages are stored as Cloudinary "video" resources.
          result = await cloudinary.uploader.destroy(publicId, {
            resource_type: "video",
            invalidate: true,
          });
        }
        if (result.result === "ok" || result.result === "not found") {
          await this.prisma.message.updateMany({
            where: { type: "expired", mediaPublicId: publicId },
            data: { mediaPublicId: null },
          });
        }
      } catch (error) {
        this.logger.warn(`Expired chat media cleanup failed: ${String(error)}`);
      }
    }
  }

  async sendImage(
    clerkUserId: string,
    conversationId: string,
    clientMessageId: string,
    rawCaption: string,
    file?: Express.Multer.File,
  ) {
    if (!clientMessageId || clientMessageId.length > 100) {
      throw new BadRequestException("Invalid client message ID.");
    }
    const text = rawCaption.trim();
    if (text.length > 4000) {
      throw new BadRequestException("Image caption is too long.");
    }
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User account was not found.");
    const conversation = await this.messages.assertParticipant(
      user.id,
      conversationId,
    );
    const existing = await this.prisma.message.findUnique({
      where: {
        senderId_clientMessageId: { senderId: user.id, clientMessageId },
      },
    });
    if (existing) {
      if (existing.conversationId !== conversationId) {
        throw new BadRequestException("Duplicate message ID.");
      }
      return this.messages.messageResponse(existing);
    }
    if (!file || !this.validImage(file)) {
      throw new BadRequestException(
        "Choose a JPEG, PNG, or WebP image up to 10 MB.",
      );
    }

    let uploaded: UploadApiResponse;
    try {
      uploaded = await new Promise<UploadApiResponse>((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            folder: `matchify/messages/${user.id}`,
            resource_type: "image",
            overwrite: false,
            allowed_formats: ["jpg", "jpeg", "png", "webp"],
          },
          (error, result) =>
            error || !result
              ? reject(error ?? new Error("Upload returned no image"))
              : resolve(result),
        );
        stream.end(file.buffer);
      });
    } catch (error) {
      this.logger.warn(
        `Message image upload failed for ${user.id}: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new ServiceUnavailableException("Image upload failed. Try again.");
    }

    try {
      const message = await this.prisma.$transaction(async (tx) => {
        const saved = await tx.message.create({
          data: {
            conversationId,
            senderId: user.id,
            clientMessageId,
            text,
            type: "image",
            mediaUrl: uploaded.secure_url,
            mediaPublicId: uploaded.public_id,
            mediaMimeType: `image/${uploaded.format === "jpg" ? "jpeg" : uploaded.format}`,
            mediaSize: file.size,
          },
        });
        await tx.conversation.update({
          where: { id: conversationId },
          data: {
            updatedAt: new Date(),
            ...(conversation.userOneId === user.id
              ? { userTwoUnreadCount: { increment: 1 } }
              : { userOneUnreadCount: { increment: 1 } }),
          },
        });
        return saved;
      });
      return this.messages.messageResponse(message);
    } catch (error) {
      await cloudinary.uploader
        .destroy(uploaded.public_id, { resource_type: "image" })
        .catch(() => undefined);
      const duplicate = await this.prisma.message.findUnique({
        where: {
          senderId_clientMessageId: { senderId: user.id, clientMessageId },
        },
      });
      if (duplicate?.conversationId === conversationId) {
        return this.messages.messageResponse(duplicate);
      }
      throw error;
    }
  }

  async sendVoice(
    clerkUserId: string,
    conversationId: string,
    clientMessageId: string,
    rawDurationMs: unknown,
    file?: Express.Multer.File,
  ) {
    if (!clientMessageId || clientMessageId.length > 100) {
      throw new BadRequestException("Invalid client message ID.");
    }
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User account was not found.");
    const conversation = await this.messages.assertParticipant(
      user.id,
      conversationId,
    );
    const existing = await this.prisma.message.findUnique({
      where: {
        senderId_clientMessageId: { senderId: user.id, clientMessageId },
      },
    });
    if (existing) {
      if (existing.conversationId !== conversationId) {
        throw new BadRequestException("Duplicate message ID.");
      }
      return this.messages.messageResponse(existing);
    }
    const durationMs = this.voiceNotes.assertValid(file, rawDurationMs);
    const audio = await this.voiceNotes.upload(
      file!,
      `matchify/messages/${user.id}/voice`,
      durationMs,
    );

    try {
      const message = await this.prisma.$transaction(async (tx) => {
        const saved = await tx.message.create({
          data: {
            conversationId,
            senderId: user.id,
            clientMessageId,
            text: "",
            type: "voice",
            mediaUrl: audio.url,
            mediaPublicId: audio.publicId,
            mediaMimeType: audio.mimeType,
            mediaSize: audio.size,
            mediaDurationMs: audio.durationMs,
          },
        });
        await tx.conversation.update({
          where: { id: conversationId },
          data: {
            updatedAt: new Date(),
            ...(conversation.userOneId === user.id
              ? { userTwoUnreadCount: { increment: 1 } }
              : { userOneUnreadCount: { increment: 1 } }),
          },
        });
        return saved;
      });
      return this.messages.messageResponse(message);
    } catch (error) {
      await this.voiceNotes.destroy(audio.publicId);
      const duplicate = await this.prisma.message.findUnique({
        where: {
          senderId_clientMessageId: { senderId: user.id, clientMessageId },
        },
      });
      if (duplicate?.conversationId === conversationId) {
        return this.messages.messageResponse(duplicate);
      }
      throw error;
    }
  }

  private validImage(file: Express.Multer.File): boolean {
    if (file.size > 10 * 1024 * 1024 || file.size < 16) return false;
    const data = file.buffer;
    const jpeg = data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff;
    const png = data
      .subarray(0, 8)
      .equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    const webp =
      data.toString("ascii", 0, 4) === "RIFF" &&
      data.toString("ascii", 8, 12) === "WEBP";
    return jpeg || png || webp;
  }
}
