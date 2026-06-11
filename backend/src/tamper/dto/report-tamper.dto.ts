import { TamperKind } from '@prisma/client';
import { IsEnum, IsISO8601, IsOptional, IsString } from 'class-validator';

export class ReportTamperDto {
  @IsEnum(TamperKind)
  kind!: TamperKind;

  @IsOptional()
  @IsString()
  detail?: string;

  @IsOptional()
  @IsISO8601()
  occurredAt?: string;
}
