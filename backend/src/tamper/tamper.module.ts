import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { TamperController } from './tamper.controller';
import { TamperService } from './tamper.service';

@Module({
  imports: [DevicesModule],
  controllers: [TamperController],
  providers: [TamperService],
  exports: [TamperService], // HeartbeatService raises WENT_DARK / RECOVERED
})
export class TamperModule {}
