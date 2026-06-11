import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentDevice } from '../common/decorators/current-device.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthDevice, AuthUser } from '../common/types';
import { DevicesService } from './devices.service';
import { DeviceSelfUpdateDto } from './dto/device-self-update.dto';
import { DeviceTokenDto } from './dto/device-token.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';

@Controller('devices')
export class DevicesController {
  constructor(private readonly devices: DevicesService) {}

  // ---- device-self (device token). Declared before :id so /devices/me wins. ----

  @Get('me')
  @UseGuards(DeviceAuthGuard)
  me(@CurrentDevice() device: AuthDevice) {
    return this.devices.getSelf(device.deviceId);
  }

  @Patch('me')
  @UseGuards(DeviceAuthGuard)
  updateMe(@CurrentDevice() device: AuthDevice, @Body() dto: DeviceSelfUpdateDto) {
    return this.devices.selfUpdate(device.deviceId, dto);
  }

  @Post('token')
  @HttpCode(HttpStatus.OK)
  token(@Body() dto: DeviceTokenDto) {
    return this.devices.reauth(dto.deviceId, dto.secret);
  }

  // ---- parent (access token) ----

  @Get()
  @UseGuards(JwtAuthGuard)
  list(@CurrentUser() user: AuthUser) {
    return this.devices.listForFamily(user.familyId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  get(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.devices.getForFamily(user.familyId, id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  rename(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateDeviceDto,
  ) {
    return this.devices.rename(user.familyId, id, dto.name);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.devices.remove(user.familyId, id);
  }
}
