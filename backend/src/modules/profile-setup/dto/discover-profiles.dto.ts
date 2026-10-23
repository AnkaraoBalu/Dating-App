import { Transform, Type } from "class-transformer";
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from "class-validator";

export class DiscoverProfilesQueryDto {
  @IsOptional()
  @IsDateString()
  replayBefore?: string;
  @IsOptional()
  @Transform(({ value }) => value === true || value === "true")
  @IsBoolean()
  includeStatus?: boolean;
  @IsOptional()
  @IsIn(["for_you", "nearby", "trending", "online", "new"])
  mode?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(18) @Max(70) minAge?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(18) @Max(70) maxAge?: number;
  @IsOptional()
  @IsIn(["man", "woman", "non_binary", "everyone"])
  gender?: string;
  @IsOptional() @IsString() @MaxLength(120) location?: string;
  @IsOptional() @IsString() @MaxLength(40) interest?: string;
  @IsOptional()
  @Transform(({ value }) =>
    Array.isArray(value)
      ? value
      : typeof value === "string"
        ? value.split(",")
        : value,
  )
  @IsArray()
  @ArrayMaxSize(8)
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  interests?: string[];
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  radiusKm?: number;
  @IsOptional()
  @Transform(({ value }) => value === true || value === "true")
  @IsBoolean()
  onlineOnly?: boolean;
  @IsOptional()
  @Transform(({ value }) => value === true || value === "true")
  @IsBoolean()
  verifiedOnly?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number;
}
