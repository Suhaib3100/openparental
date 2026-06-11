import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class DeviceSelfUpdateDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  batteryPct?: number;

  @IsOptional()
  @IsString()
  osVersion?: string;

  @IsOptional()
  @IsString()
  appVersion?: string;

  @IsOptional()
  @IsString()
  fcmToken?: string;
}
