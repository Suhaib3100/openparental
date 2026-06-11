import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { PairingController } from './pairing.controller';
import { PairingService } from './pairing.service';

@Module({
  imports: [DevicesModule],
  controllers: [PairingController],
  providers: [PairingService],
})
export class PairingModule {}
