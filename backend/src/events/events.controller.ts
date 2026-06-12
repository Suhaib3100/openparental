import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { EventType } from '@prisma/client';
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
    @Query('type') type?: EventType,
  ) {
    return this.events.listForFamilyDevice(
      user.familyId,
      deviceId,
      limit ? parseInt(limit, 10) : undefined,
      type,
    );
  }

  @Get('devices/:deviceId/usage-report')
  @UseGuards(JwtAuthGuard)
  usageReport(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
  ) {
    return this.events.usageReport(user.familyId, deviceId);
  }

  @Get('devices/:deviceId/permissions')
  @UseGuards(JwtAuthGuard)
  permissions(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
  ) {
    return this.events.latestPermissions(user.familyId, deviceId);
  }

  @Get('devices/:deviceId/apps')
  @UseGuards(JwtAuthGuard)
  apps(@CurrentUser() user: AuthUser, @Param('deviceId') deviceId: string) {
    return this.events.installedApps(user.familyId, deviceId);
  }
}
