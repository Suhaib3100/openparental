import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
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
import { LocationsService } from './locations.service';
import { ReportLocationDto } from './dto/report-location.dto';

@Controller()
export class LocationsController {
  constructor(private readonly locations: LocationsService) {}

  @Post('locations')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(DeviceAuthGuard)
  ingest(@CurrentDevice() device: AuthDevice, @Body() dto: ReportLocationDto) {
    return this.locations.ingest(device.deviceId, dto);
  }

  // Declared before the list route so /locations/latest resolves correctly.
  @Get('devices/:deviceId/locations/latest')
  @UseGuards(JwtAuthGuard)
  latest(@CurrentUser() user: AuthUser, @Param('deviceId') deviceId: string) {
    return this.locations.latest(user.familyId, deviceId);
  }

  @Get('devices/:deviceId/locations')
  @UseGuards(JwtAuthGuard)
  history(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
    @Query('limit') limit?: string,
  ) {
    return this.locations.history(
      user.familyId,
      deviceId,
      limit ? parseInt(limit, 10) : undefined,
    );
  }
}
