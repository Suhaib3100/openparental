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
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/types';
import { ClaimPairingDto } from './dto/claim-pairing.dto';
import { CreatePairingDto } from './dto/create-pairing.dto';
import { PairingService } from './pairing.service';

@Controller('pairings')
export class PairingController {
  constructor(private readonly pairing: PairingService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: AuthUser, @Body() dto: CreatePairingDto) {
    return this.pairing.create(user.familyId, dto);
  }

  /** Public: the device authenticates itself via the QR token / code. */
  @Post('claim')
  @HttpCode(HttpStatus.OK)
  claim(@Body() dto: ClaimPairingDto) {
    return this.pairing.claim(dto);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  status(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.pairing.getStatus(user.familyId, id);
  }
}
