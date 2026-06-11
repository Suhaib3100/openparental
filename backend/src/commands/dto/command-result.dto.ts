import { IsObject, IsOptional, IsString } from 'class-validator';

export class CommandResultDto {
  @IsOptional()
  @IsObject()
  result?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  error?: string;
}
