import { Type } from "class-transformer";
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from "class-validator";

export class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(120) industry?: string;
  @IsOptional()
  @IsIn(["no", "sometimes", "yes", "prefer_not_to_say"])
  smoking?: string;
  @IsOptional()
  @IsIn(["never", "socially", "regularly", "prefer_not_to_say"])
  drinking?: string;
  @IsOptional()
  @IsIn(["vegetarian", "vegan", "non_vegetarian", "pescatarian", "other"])
  diet?: string;
  @IsOptional() @IsString() @MaxLength(80) religion?: string;
  @IsOptional() @IsBoolean() showProfile?: boolean;
  @IsOptional() @IsBoolean() showDistance?: boolean;
  @IsOptional() @IsBoolean() showOnlineStatus?: boolean;
  @IsOptional() @IsString() @MaxLength(200) bio?: string;
  @IsOptional() @IsString() @MaxLength(120) location?: string;
  @IsOptional() @IsString() @MaxLength(120) education?: string;
  @IsOptional() @IsString() @MaxLength(120) fieldOfStudy?: string | null;
  @IsOptional() @IsString() @MaxLength(120) jobTitle?: string;
  @IsOptional() @IsString() @MaxLength(120) company?: string;
  @IsOptional() @IsInt() @Min(90) @Max(250) heightCm?: number;
  @IsOptional() @IsString() @MaxLength(40) zodiac?: string;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @ArrayUnique()
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  languages?: string[];
}

export class ProfilePromptDto {
  @IsString() @IsNotEmpty() @MaxLength(120) question!: string;
  @IsString() @IsNotEmpty() @MaxLength(150) answer!: string;
}

export class SavePromptsDto {
  @IsArray()
  @ArrayMaxSize(5)
  @ArrayUnique((prompt: ProfilePromptDto) => prompt.question)
  @ValidateNested({ each: true })
  @Type(() => ProfilePromptDto)
  prompts!: ProfilePromptDto[];
}

export class ReorderPhotosDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(6)
  @ArrayUnique()
  @IsString({ each: true })
  photoIds!: string[];
}
