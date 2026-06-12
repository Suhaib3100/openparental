import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsISO8601,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

/** One archived item (an SMS, call-log row, browser visit, …). */
export class ContentItemDto {
  @IsIn(['sms', 'calllog', 'whatsapp', 'browser', 'tiktok', 'youtube', 'keyword'])
  source!: string;

  @IsOptional()
  @IsIn(['in', 'out'])
  direction?: string;

  @IsOptional()
  @IsString()
  @MaxLength(256)
  counterparty?: string;

  @IsString()
  @MaxLength(8192)
  body!: string;

  /** A matched watch-word, if the on-device scan flagged this item. */
  @IsOptional()
  @IsString()
  @MaxLength(128)
  matched?: string;

  @IsISO8601()
  occurredAt!: string;
}

export class IngestContentDto {
  @IsArray()
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => ContentItemDto)
  items!: ContentItemDto[];
}
