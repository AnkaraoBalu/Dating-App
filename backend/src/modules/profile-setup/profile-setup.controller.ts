import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ClerkAuthGuard, ClerkRequest } from "../auth/clerk-auth.guard";
import {
  ReorderPhotosDto,
  SavePromptsDto,
  UpdateProfileDto,
} from "./dto/profile-setup.dto";
import { ProfileSetupService } from "./profile-setup.service";
import { DiscoverProfilesQueryDto } from "./dto/discover-profiles.dto";

@Controller("profile")
@UseGuards(ClerkAuthGuard)
export class ProfileSetupController {
  constructor(private readonly profiles: ProfileSetupService) {}

  @Get() get(@Req() request: ClerkRequest) {
    return this.profiles.get(request.auth.userId);
  }
  @Get("discover") discover(
    @Req() request: ClerkRequest,
    @Query() query: DiscoverProfilesQueryDto,
  ) {
    return this.profiles.discover(request.auth.userId, query);
  }
  @Post("discover/:userId/like") like(
    @Req() request: ClerkRequest,
    @Param("userId") userId: string,
  ) {
    return this.profiles.like(request.auth.userId, userId);
  }
  @Post("discover/:userId/pass") pass(
    @Req() request: ClerkRequest,
    @Param("userId") userId: string,
  ) {
    return this.profiles.pass(request.auth.userId, userId);
  }
  @Get("insights") insights(@Req() request: ClerkRequest) {
    return this.profiles.insights(request.auth.userId);
  }
  @Get("matches") matches(
    @Req() request: ClerkRequest,
    @Query("search") search?: string,
  ) {
    return this.profiles.matches(request.auth.userId, search);
  }
  @Get("likes/received") incomingLikes(@Req() request: ClerkRequest) {
    return this.profiles.incomingLikes(request.auth.userId);
  }
  @Put("photos/:id")
  @UseInterceptors(
    FileInterceptor("file", {
      limits: { fileSize: 5 * 1024 * 1024, files: 1 },
    }),
  )
  replacePhoto(
    @Req() request: ClerkRequest,
    @Param("id") id: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.profiles.replacePhoto(request.auth.userId, id, file);
  }
  @Patch() update(
    @Req() request: ClerkRequest,
    @Body() body: UpdateProfileDto,
  ) {
    return this.profiles.update(request.auth.userId, body);
  }
  @Put("prompts") savePrompts(
    @Req() request: ClerkRequest,
    @Body() body: SavePromptsDto,
  ) {
    return this.profiles.savePrompts(request.auth.userId, body);
  }
  @Post("photos")
  @UseInterceptors(
    FileInterceptor("file", {
      limits: { fileSize: 5 * 1024 * 1024, files: 1 },
    }),
  )
  addPhoto(
    @Req() request: ClerkRequest,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.profiles.addPhoto(request.auth.userId, file);
  }
  @Patch("photos/order") reorderPhotos(
    @Req() request: ClerkRequest,
    @Body() body: ReorderPhotosDto,
  ) {
    return this.profiles.reorderPhotos(request.auth.userId, body);
  }
  @Delete("photos/:id") removePhoto(
    @Req() request: ClerkRequest,
    @Param("id") id: string,
  ) {
    return this.profiles.removePhoto(request.auth.userId, id);
  }
  @Post("complete") complete(@Req() request: ClerkRequest) {
    return this.profiles.complete(request.auth.userId);
  }
}
