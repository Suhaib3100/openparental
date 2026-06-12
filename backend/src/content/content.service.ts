import { Injectable } from '@nestjs/common';
import { ContentArchive, Prisma } from '@prisma/client';
import { AlertsService } from '../alerts/alerts.service';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { IngestContentDto } from './dto/ingest-content.dto';

/**
 * Content archive (AMBER / v1.5). The device — with disclosed, on-device
 * consent — batches messages/visits here so a parent can review them. Watch-word
 * matches raise a single KEYWORD alert per batch (no per-message spam).
 */
@Injectable()
export class ContentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
    private readonly alerts: AlertsService,
  ) {}

  async ingest(
    deviceId: string,
    dto: IngestContentDto,
  ): Promise<{ ingested: number }> {
    const items = dto.items ?? [];
    if (items.length === 0) return { ingested: 0 };

    await this.prisma.contentArchive.createMany({
      data: items.map((i) => ({
        deviceId,
        source: i.source,
        direction: i.direction ?? null,
        counterparty: i.counterparty ?? null,
        body: i.body,
        matched: i.matched ?? null,
        occurredAt: new Date(i.occurredAt),
      })),
    });
    await this.touchDevice(deviceId);

    const matched = items.filter((i) => i.matched);
    if (matched.length > 0) {
      const device = await this.prisma.device.findUnique({
        where: { id: deviceId },
        select: { familyId: true },
      });
      if (device) {
        const words = Array.from(
          new Set(matched.map((m) => m.matched as string)),
        ).slice(0, 5);
        await this.alerts.create({
          familyId: device.familyId,
          deviceId,
          type: 'KEYWORD',
          title: 'Keyword match',
          body: `Flagged ${matched.length} message(s): ${words.join(', ')}`,
          data: { words, source: matched[0].source } as Prisma.InputJsonValue,
        });
      }
    }
    return { ingested: items.length };
  }

  async list(
    familyId: string,
    deviceId: string,
    source?: string,
    limit = 100,
  ): Promise<ContentArchive[]> {
    await this.devices.getForFamily(familyId, deviceId); // ownership check
    return this.prisma.contentArchive.findMany({
      where: { deviceId, ...(source ? { source } : {}) },
      orderBy: { occurredAt: 'desc' },
      take: Math.min(limit, 500),
    });
  }

  private touchDevice(deviceId: string): Promise<unknown> {
    return this.prisma.device
      .update({ where: { id: deviceId }, data: { lastSeenAt: new Date() } })
      .catch(() => undefined);
  }
}
