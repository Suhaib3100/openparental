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
import { TamperService } from './tamper.service';
import { ReportTamperDto } from './dto/report-tamper.dto';

@Controller()
export class TamperController {
  constructor(private readonly tamper: TamperService) {}

  @Post('tamper')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(DeviceAuthGuard)
  report(@CurrentDevice() device: AuthDevice, @Body() dto: ReportTamperDto) {
    return this.tamper.reportFromDevice(device.familyId, device.deviceId, dto);
  }

  @Get('devices/:deviceId/tamper')
  @UseGuards(JwtAuthGuard)
  list(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
    @Query('limit') limit?: string,
  ) {
    return this.tamper.listForFamilyDevice(
      user.familyId,
      deviceId,
      limit ? parseInt(limit, 10) : undefined,
    );
  }
}
