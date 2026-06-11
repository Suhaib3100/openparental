import { EventType } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsISO8601,
  IsObject,
  ValidateNested,
} from 'class-validator';

export class EventInput {
  @IsEnum(EventType)
  type!: EventType;

  @IsObject()
  data!: Record<string, unknown>;

  @IsISO8601()
  occurredAt!: string;
}

export class IngestEventsDto {
  @IsArray()
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => EventInput)
  events!: EventInput[];
}
