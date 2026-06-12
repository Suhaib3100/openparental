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
import { ContentService } from './content.service';
import { IngestContentDto } from './dto/ingest-content.dto';

@Controller()
export class ContentController {
  constructor(private readonly content: ContentService) {}

  @Post('content')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(DeviceAuthGuard)
  ingest(@CurrentDevice() device: AuthDevice, @Body() dto: IngestContentDto) {
    return this.content.ingest(device.deviceId, dto);
  }

  @Get('devices/:deviceId/content')
  @UseGuards(JwtAuthGuard)
  list(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
    @Query('source') source?: string,
    @Query('limit') limit?: string,
  ) {
    return this.content.list(
      user.familyId,
      deviceId,
      source,
      limit ? parseInt(limit, 10) : undefined,
    );
  }
}
