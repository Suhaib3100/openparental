import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { EventsController } from './events.controller';
import { EventsService } from './events.service';

@Module({
  imports: [DevicesModule],
  controllers: [EventsController],
  providers: [EventsService],
})
export class EventsModule {}
