import { IsOptional, IsString } from 'class-validator';

export class CreatePairingDto {
  @IsOptional()
  @IsString()
  deviceName?: string;
}
