import { IsString, MinLength } from 'class-validator';

export class UpdateDeviceDto {
  @IsString()
  @MinLength(1)
  name!: string;
}
