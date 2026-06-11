import { IsOptional, IsString } from 'class-validator';

export class RequestUnblockDto {
  @IsOptional()
  @IsString()
  appPackage?: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
