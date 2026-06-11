import { Injectable } from '@nestjs/common';
import { Event, Prisma } from '@prisma/client';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { IngestEventsDto } from './dto/ingest-events.dto';

@Injectable()
export class EventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
  ) {}

  /** Device flushes a batch of buffered events (usage, foreground app, etc.). */
  async ingestBatch(
    deviceId: string,
    dto: IngestEventsDto,
  ): Promise<{ count: number }> {
    if (dto.events.length === 0) return { count: 0 };
    const result = await this.prisma.event.createMany({
      data: dto.events.map((e) => ({
        deviceId,
        type: e.type,
        data: e.data as Prisma.InputJsonValue,
        occurredAt: new Date(e.occurredAt),
      })),
    });
    await this.prisma.device
      .update({ where: { id: deviceId }, data: { lastSeenAt: new Date() } })
      .catch(() => undefined);
    return { count: result.count };
  }

  async listForFamilyDevice(
    familyId: string,
    deviceId: string,
    limit = 200,
  ): Promise<Event[]> {
    await this.devices.getForFamily(familyId, deviceId); // ownership
    return this.prisma.event.findMany({
      where: { deviceId },
      orderBy: { occurredAt: 'desc' },
      take: Math.min(limit, 500),
    });
  }
}
