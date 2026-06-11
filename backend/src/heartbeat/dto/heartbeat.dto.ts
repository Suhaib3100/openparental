import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class HeartbeatDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  batteryPct?: number;
}
