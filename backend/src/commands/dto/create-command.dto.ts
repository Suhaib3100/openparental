import { CommandType } from '@prisma/client';
import { IsEnum, IsObject, IsOptional, IsString } from 'class-validator';

export class CreateCommandDto {
  @IsEnum(CommandType)
  type!: CommandType;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;

  /** Optional client-supplied key; if a command with it exists, it's returned as-is. */
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}
