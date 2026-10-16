import { IsIn, IsOptional, IsString, MaxLength } from "class-validator";

export const reportReasons = [
  "fake_profile",
  "inappropriate_photos",
  "harassment",
  "offensive_messages",
  "scam_or_spam",
  "underage",
  "other",
] as const;

export const reportSources = ["profile", "discover", "chat", "match"] as const;

export class ReportUserDto {
  @IsIn(reportReasons)
  reason!: (typeof reportReasons)[number];

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  details?: string;

  @IsOptional()
  @IsIn(reportSources)
  source?: (typeof reportSources)[number];
}
