import { IsNotEmpty, IsString, MaxLength } from "class-validator";

export class UpdateNameDto {
  @IsString() @IsNotEmpty() @MaxLength(80) username!: string;
}
