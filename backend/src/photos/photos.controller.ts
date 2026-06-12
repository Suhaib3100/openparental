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
import { PhotosService } from './photos.service';
import { IngestPhotoFlagsDto } from './dto/ingest-photo-flags.dto';

@Controller()
export class PhotosController {
  constructor(private readonly photos: PhotosService) {}

  @Post('photo-flags')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(DeviceAuthGuard)
  ingest(@CurrentDevice() device: AuthDevice, @Body() dto: IngestPhotoFlagsDto) {
    return this.photos.ingest(device.deviceId, dto);
  }

  @Get('devices/:deviceId/photo-flags')
  @UseGuards(JwtAuthGuard)
  list(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
    @Query('limit') limit?: string,
  ) {
    return this.photos.list(
      user.familyId,
      deviceId,
      limit ? parseInt(limit, 10) : undefined,
    );
  }
}
