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
import { AlertsService } from './alerts.service';
import { RequestUnblockDto } from './dto/request-unblock.dto';

@Controller()
export class AlertsController {
  constructor(private readonly alerts: AlertsService) {}

  @Get('alerts')
  @UseGuards(JwtAuthGuard)
  list(@CurrentUser() user: AuthUser, @Query('unread') unread?: string) {
    return this.alerts.listForFamily(user.familyId, unread === 'true');
  }

  @Post('alerts/:id/read')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  read(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.alerts.markRead(user.familyId, id);
  }

  @Post('alerts/request-unblock')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(DeviceAuthGuard)
  requestUnblock(
    @CurrentDevice() device: AuthDevice,
    @Body() dto: RequestUnblockDto,
  ) {
    return this.alerts.requestUnblock(device.familyId, device.deviceId, dto);
  }
}
