import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsISO8601,
  IsNumber,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

/**
 * A single on-device image classification result. CATEGORY + SCORE ONLY —
 * never the image bytes, never a thumbnail, never a hash of the content.
 * (CSAM strict liability — see the PhotoFlag model comment in schema.prisma.)
 */
export class PhotoFlagItemDto {
  @IsString()
  @MaxLength(64)
  category!: string;

  @IsNumber()
  @Min(0)
  @Max(1)
  confidence!: number;

  @IsISO8601()
  occurredAt!: string;
}

export class IngestPhotoFlagsDto {
  @IsArray()
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => PhotoFlagItemDto)
  items!: PhotoFlagItemDto[];
}
