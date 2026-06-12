import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { PhotosController } from './photos.controller';
import { PhotosService } from './photos.service';

@Module({
  imports: [DevicesModule],
  controllers: [PhotosController],
  providers: [PhotosService],
})
export class PhotosModule {}
