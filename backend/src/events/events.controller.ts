import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentDevice } from '../common/decorators/current-device.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthDevice, AuthUser } from '../common/types';
import { EventsService } from './events.service';
import { IngestEventsDto } from './dto/ingest-events.dto';

@Controller()
export class EventsController {
  constructor(private readonly events: EventsService) {}

  @Post('events')
  @UseGuards(DeviceAuthGuard)
  ingest(@CurrentDevice() device: AuthDevice, @Body() dto: IngestEventsDto) {
    return this.events.ingestBatch(device.deviceId, dto);
  }

  @Get('devices/:deviceId/events')
  @UseGuards(JwtAuthGuard)
  list(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
    @Query('limit') limit?: string,
  ) {
    return this.events.listForFamilyDevice(
      user.familyId,
      deviceId,
      limit ? parseInt(limit, 10) : undefined,
    );
  }
}
