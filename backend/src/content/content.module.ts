import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { ContentController } from './content.controller';
import { ContentService } from './content.service';

@Module({
  imports: [DevicesModule],
  controllers: [ContentController],
  providers: [ContentService],
})
export class ContentModule {}
