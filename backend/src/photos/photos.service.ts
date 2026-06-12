import { Injectable } from '@nestjs/common';
import { PhotoFlag, Prisma } from '@prisma/client';
import { AlertsService } from '../alerts/alerts.service';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { IngestPhotoFlagsDto } from './dto/ingest-photo-flags.dto';

/**
 * Photo flags (AMBER / v1.5). An on-device classifier labels images as
 * sensitive and sends ONLY the category + confidence here — the image never
 * leaves the device. This is deliberately NOT CSAM / NCMEC hash matching:
 * that needs ESP enrollment + mandatory-reporting handling and cannot be
 * self-hosted. See the PhotoFlag model comment in schema.prisma.
 */
const ALERT_THRESHOLD = 0.8;
const ALERTABLE = new Set(['explicit', 'nudity', 'sexual']);

@Injectable()
export class PhotosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
    private readonly alerts: AlertsService,
  ) {}

  async ingest(
    deviceId: string,
    dto: IngestPhotoFlagsDto,
  ): Promise<{ ingested: number }> {
    const items = dto.items ?? [];
    if (items.length === 0) return { ingested: 0 };

    await this.prisma.photoFlag.createMany({
      data: items.map((i) => ({
        deviceId,
        category: i.category,
        confidence: i.confidence,
        occurredAt: new Date(i.occurredAt),
      })),
    });
    await this.prisma.device
      .update({ where: { id: deviceId }, data: { lastSeenAt: new Date() } })
      .catch(() => undefined);

    const serious = items.filter(
      (i) =>
        i.confidence >= ALERT_THRESHOLD && ALERTABLE.has(i.category.toLowerCase()),
    );
    if (serious.length > 0) {
      const device = await this.prisma.device.findUnique({
        where: { id: deviceId },
        select: { familyId: true },
      });
      if (device) {
        await this.alerts.create({
          familyId: device.familyId,
          deviceId,
          type: 'PHOTO_FLAG',
          title: 'Sensitive image flagged',
          body: `${serious.length} image(s) flagged on the device (${serious[0].category}). The image stays on the device.`,
          data: {
            count: serious.length,
            category: serious[0].category,
          } as Prisma.InputJsonValue,
        });
      }
    }
    return { ingested: items.length };
  }

  async list(
    familyId: string,
    deviceId: string,
    limit = 100,
  ): Promise<PhotoFlag[]> {
    await this.devices.getForFamily(familyId, deviceId); // ownership check
    return this.prisma.photoFlag.findMany({
      where: { deviceId },
      orderBy: { occurredAt: 'desc' },
      take: Math.min(limit, 500),
    });
  }
}
