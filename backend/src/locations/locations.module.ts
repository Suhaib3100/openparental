import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { LocationsController } from './locations.controller';
import { LocationsService } from './locations.service';

@Module({
  imports: [DevicesModule],
  controllers: [LocationsController],
  providers: [LocationsService],
})
export class LocationsModule {}
