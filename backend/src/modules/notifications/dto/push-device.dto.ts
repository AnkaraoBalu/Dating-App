import { IsIn, IsNotEmpty, IsString, MaxLength } from "class-validator";

export class RegisterPushDeviceDto {
  @IsString() @IsNotEmpty() @MaxLength(4096) token!: string;
  @IsIn(["android", "ios"]) platform!: "android" | "ios";
}

export class RemovePushDeviceDto {
  @IsString() @IsNotEmpty() @MaxLength(4096) token!: string;
}
