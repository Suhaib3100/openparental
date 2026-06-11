import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentDevice } from '../common/decorators/current-device.decorator';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { AuthDevice } from '../common/types';
import { HeartbeatService } from './heartbeat.service';
import { HeartbeatDto } from './dto/heartbeat.dto';

@Controller('heartbeat')
export class HeartbeatController {
  constructor(private readonly heartbeat: HeartbeatService) {}

  @Post()
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(DeviceAuthGuard)
  async beat(@CurrentDevice() device: AuthDevice, @Body() dto: HeartbeatDto) {
    await this.heartbeat.beat(device.familyId, device.deviceId, dto.batteryPct);
  }
}
