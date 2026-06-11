import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentDevice } from '../common/decorators/current-device.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthDevice, AuthUser } from '../common/types';
import { CommandsService } from './commands.service';
import { CommandResultDto } from './dto/command-result.dto';
import { CreateCommandDto } from './dto/create-command.dto';

@Controller()
export class CommandsController {
  constructor(private readonly commands: CommandsService) {}

  // ---- parent (access token) ----

  @Post('devices/:deviceId/commands')
  @UseGuards(JwtAuthGuard)
  enqueue(
    @CurrentUser() user: AuthUser,
    @Param('deviceId') deviceId: string,
    @Body() dto: CreateCommandDto,
  ) {
    return this.commands.enqueue(user.familyId, deviceId, dto);
  }

  @Get('devices/:deviceId/commands')
  @UseGuards(JwtAuthGuard)
  list(@CurrentUser() user: AuthUser, @Param('deviceId') deviceId: string) {
    return this.commands.listForFamilyDevice(user.familyId, deviceId);
  }

  // ---- device (device token). 'pending' before ':id' so the static path wins. ----

  @Get('commands/pending')
  @UseGuards(DeviceAuthGuard)
  pending(@CurrentDevice() device: AuthDevice) {
    return this.commands.pullPending(device.deviceId);
  }

  @Post('commands/:id/ack')
  @HttpCode(HttpStatus.OK)
  @UseGuards(DeviceAuthGuard)
  ack(@CurrentDevice() device: AuthDevice, @Param('id') id: string) {
    return this.commands.ack(device.deviceId, id);
  }

  @Post('commands/:id/result')
  @HttpCode(HttpStatus.OK)
  @UseGuards(DeviceAuthGuard)
  result(
    @CurrentDevice() device: AuthDevice,
    @Param('id') id: string,
    @Body() dto: CommandResultDto,
  ) {
    return this.commands.complete(device.deviceId, id, dto);
  }

  // ---- parent status ----

  @Get('commands/:id')
  @UseGuards(JwtAuthGuard)
  get(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.commands.getForFamily(user.familyId, id);
  }
}
