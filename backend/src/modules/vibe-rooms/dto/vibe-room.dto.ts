import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from "class-validator";
import { Type } from "class-transformer";

export class ListVibeRoomsQueryDto {
  @IsOptional() @IsString() @MaxLength(80) categoryId?: string;
  @IsOptional() @IsString() @MaxLength(100) search?: string;
}

export class CreateVibeRoomDto {
  @IsString() @IsNotEmpty() @MaxLength(40) title!: string;
  @IsString() @IsNotEmpty() @MaxLength(1000) description!: string;
  @IsString() @IsNotEmpty() @MaxLength(80) categoryId!: string;
  @IsString() @IsNotEmpty() @MaxLength(16) emoji!: string;
  @IsString() @IsNotEmpty() @MaxLength(255) coverAsset!: string;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @ArrayUnique()
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  tags?: string[];
  @IsOptional() @IsString() @MaxLength(120) city?: string;
  @IsInt() @Min(10) @Max(100) maxParticipants!: number;
  @IsBoolean() inviteOnly!: boolean;
}

export class SetVibeRoomSavedDto {
  @IsBoolean() saved!: boolean;
}

export class CreateVibeRoomMessageDto {
  @IsString() @IsNotEmpty() @MaxLength(80) clientMessageId!: string;
  @IsString() @IsNotEmpty() @MaxLength(1000) text!: string;
}

export class ListVibeRoomMessagesQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit = 50;
}

export class CreateVibeGameDto {
  @IsString() @IsNotEmpty() @MaxLength(40) gameType!: string;
  @IsOptional() @IsObject() setup?: {
    statements?: string[];
    lieIndex?: number;
  };
}

export class SubmitVibeGameAnswerDto {
  @Type(() => Number) @IsInt() @Min(0) questionIndex!: number;
  @Type(() => Number) @IsInt() @Min(0) @Max(2) choiceIndex!: number;
}
