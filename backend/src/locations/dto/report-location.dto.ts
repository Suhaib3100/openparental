import { IsISO8601, IsNumber, IsOptional, Max, Min } from 'class-validator';

export class ReportLocationDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  @IsOptional()
  @IsNumber()
  accuracyM?: number;

  @IsOptional()
  @IsISO8601()
  occurredAt?: string;
}
