import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class ClaimPairingDto {
  /** The QR token or the short human code shown in the parent app. */
  @IsString()
  @IsNotEmpty()
  token!: string;

  @IsOptional()
  @IsString()
  deviceName?: string;

  @IsOptional()
  @IsString()
  manufacturer?: string;

  @IsOptional()
  @IsString()
  model?: string;

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
