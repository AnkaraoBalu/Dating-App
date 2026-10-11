import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ServiceUnavailableException,
  Logger,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { v2 as cloudinary, UploadApiResponse } from "cloudinary";
import { PrismaService } from "../../database/prisma.service";
import { ReorderPhotosDto } from "./dto/profile-setup.dto";
import { ProfileRepository } from "./profile.repository";

@Injectable()
export class ProfilePhotosService {
  private readonly logger = new Logger(ProfilePhotosService.name);

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
    private readonly profiles: ProfileRepository,
  ) {
    cloudinary.config({
      cloud_name: config.getOrThrow<string>("CLOUDINARY_CLOUD_NAME"),
      api_key: config.getOrThrow<string>("CLOUDINARY_API_KEY"),
      api_secret: config.getOrThrow<string>("CLOUDINARY_API_SECRET"),
      secure: true,
    });
  }

  async replacePhoto(
    clerkUserId: string,
    photoId: string,
    file?: Express.Multer.File,
  ) {
    if (!file || !this.validImage(file))
      throw new BadRequestException(
        "Choose a JPEG, PNG, or WebP image (up to 5 MB).",
      );
    const userId = await this.profiles.userId(clerkUserId);
    const photo = await this.prisma.profilePhoto.findFirst({
      where: { id: photoId, profile: { userId } },
    });
    if (!photo) throw new NotFoundException("Photo not found.");
    let uploaded: UploadApiResponse;
    try {
      uploaded = await new Promise<UploadApiResponse>((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            folder: `matchify/profiles/${userId}`,
            resource_type: "image",
            overwrite: false,
          },
          (error, result) =>
            error || !result
              ? reject(error ?? new Error("Upload failed"))
              : resolve(result),
        );
        stream.end(file.buffer);
      });
    } catch {
      throw new ServiceUnavailableException("Image upload failed. Try again.");
    }
    try {
      await this.prisma.profilePhoto.update({
        where: { id: photo.id },
        data: {
          publicId: uploaded.public_id,
          secureUrl: uploaded.secure_url,
          width: uploaded.width,
          height: uploaded.height,
        },
      });
    } catch (error) {
      await cloudinary.uploader
        .destroy(uploaded.public_id)
        .catch(() => undefined);
      throw error;
    }
    await cloudinary.uploader
      .destroy(photo.publicId)
      .catch(() =>
        this.logger.warn(`Could not remove replaced photo ${photo.id}`),
      );
    return this.profiles.get(clerkUserId);
  }

  async addPhoto(clerkUserId: string, file?: Express.Multer.File) {
    if (!file || !this.validImage(file))
      throw new BadRequestException(
        "Choose a JPEG, PNG, or WebP image (up to 5 MB).",
      );
    const profile = await this.profiles.ensureProfile(clerkUserId);
    const count = await this.prisma.profilePhoto.count({
      where: { profileId: profile.id },
    });
    if (count >= 6)
      throw new BadRequestException("You can add up to 6 photos.");
    let uploaded: UploadApiResponse;
    try {
      uploaded = await new Promise<UploadApiResponse>((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            folder: `matchify/profiles/${profile.userId}`,
            resource_type: "image",
            overwrite: false,
          },
          (error, result) =>
            error || !result
              ? reject(error ?? new Error("Upload returned no image"))
              : resolve(result),
        );
        stream.end(file.buffer);
      });
    } catch (error) {
      this.logger.error(
        `Cloudinary upload failed for user ${profile.userId}: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new ServiceUnavailableException("Image upload failed. Try again.");
    }
    try {
      await this.prisma.profilePhoto.create({
        data: {
          profileId: profile.id,
          publicId: uploaded.public_id,
          secureUrl: uploaded.secure_url,
          width: uploaded.width,
          height: uploaded.height,
          position: count,
        },
      });
    } catch (error) {
      await cloudinary.uploader
        .destroy(uploaded.public_id)
        .catch(() => undefined);
      throw error;
    }
    this.logger.log(`Profile photo added for user ${profile.userId}`);
    return this.profiles.get(clerkUserId);
  }

  async removePhoto(clerkUserId: string, photoId: string) {
    const profile = await this.profiles.ensureProfile(clerkUserId);
    const photo = await this.prisma.profilePhoto.findFirst({
      where: { id: photoId, profileId: profile.id },
    });
    if (!photo) throw new NotFoundException("Photo not found.");
    try {
      const result = await cloudinary.uploader.destroy(photo.publicId, {
        resource_type: "image",
      });
      if (result.result !== "ok" && result.result !== "not found")
        throw new Error(`Cloudinary returned ${result.result}`);
    } catch (error) {
      this.logger.error(
        `Cloudinary delete failed for photo ${photo.id}: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new ServiceUnavailableException(
        "Image deletion failed. Try again.",
      );
    }
    await this.prisma.profilePhoto.delete({ where: { id: photo.id } });
    const remaining = await this.prisma.profilePhoto.findMany({
      where: { profileId: profile.id },
      orderBy: { position: "asc" },
    });
    await this.prisma.$transaction(
      remaining.map((item, position) =>
        this.prisma.profilePhoto.update({
          where: { id: item.id },
          data: { position },
        }),
      ),
    );
    return this.profiles.get(clerkUserId);
  }

  async reorderPhotos(clerkUserId: string, dto: ReorderPhotosDto) {
    const profile = await this.profiles.ensureProfile(clerkUserId);
    const photos = await this.prisma.profilePhoto.findMany({
      where: { profileId: profile.id },
      select: { id: true },
    });
    if (
      photos.length !== dto.photoIds.length ||
      photos.some((photo) => !dto.photoIds.includes(photo.id))
    ) {
      throw new BadRequestException(
        "Include each of your photos exactly once.",
      );
    }
    await this.prisma.$transaction(
      dto.photoIds.map((id, position) =>
        this.prisma.profilePhoto.update({ where: { id }, data: { position } }),
      ),
    );
    return this.profiles.get(clerkUserId);
  }

  private validImage(file: Express.Multer.File): boolean {
    if (file.size > 5 * 1024 * 1024 || file.size < 16) return false;
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
