import { IsNotEmpty, IsString } from 'class-validator';

export class FcmTokenDto {
  @IsString()
  @IsNotEmpty()
  fcmToken!: string;
}
