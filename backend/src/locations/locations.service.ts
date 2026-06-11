import { Injectable } from '@nestjs/common';
import { Location } from '@prisma/client';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { ReportLocationDto } from './dto/report-location.dto';

@Injectable()
export class LocationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  async ingest(deviceId: string, dto: ReportLocationDto): Promise<Location> {
    const location = await this.prisma.location.create({
      data: {
        deviceId,
        lat: dto.lat,
        lng: dto.lng,
        accuracyM: dto.accuracyM,
        occurredAt: dto.occurredAt ? new Date(dto.occurredAt) : new Date(),
      },
    });
    await this.prisma.device
      .update({ where: { id: deviceId }, data: { lastSeenAt: new Date() } })
      .catch(() => undefined);
    return location;
  }

  async latest(familyId: string, deviceId: string): Promise<Location | null> {
    await this.devices.getForFamily(familyId, deviceId); // ownership
    return this.prisma.location.findFirst({
      where: { deviceId },
      orderBy: { occurredAt: 'desc' },
    });
  }

  async history(
    familyId: string,
    deviceId: string,
    limit = 100,
  ): Promise<Location[]> {
    await this.devices.getForFamily(familyId, deviceId); // ownership
    return this.prisma.location.findMany({
      where: { deviceId },
      orderBy: { occurredAt: 'desc' },
      take: Math.min(limit, 500),
    });
  }
}
