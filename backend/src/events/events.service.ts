import { Injectable } from '@nestjs/common';
import { Event, EventType, Prisma } from '@prisma/client';
import { AlertsService } from '../alerts/alerts.service';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { IngestEventsDto } from './dto/ingest-events.dto';

@Injectable()
export class EventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly devices: DevicesService,
    private readonly alerts: AlertsService,
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

    await this.fanOutAlerts(deviceId, dto.events);
    return { count: result.count };
  }

  async listForFamilyDevice(
    familyId: string,
    deviceId: string,
    limit = 200,
    type?: EventType,
  ): Promise<Event[]> {
    await this.devices.getForFamily(familyId, deviceId); // ownership
    return this.prisma.event.findMany({
      where: { deviceId, ...(type ? { type } : {}) },
      orderBy: { occurredAt: 'desc' },
      take: Math.min(limit, 500),
    });
  }

  /** Aggregate the latest usage summary + foreground timeline for the parent UI. */
  async usageReport(familyId: string, deviceId: string) {
    await this.devices.getForFamily(familyId, deviceId);
    const summary = await this.prisma.event.findFirst({
      where: { deviceId, type: 'USAGE_SUMMARY' },
      orderBy: { occurredAt: 'desc' },
    });
    const minutesByApp =
      (summary?.data as { minutesByApp?: Record<string, number> } | null)
        ?.minutesByApp ?? {};
    const totalMinutes = Object.values(minutesByApp).reduce((a, b) => a + b, 0);
    const topApp = Object.entries(minutesByApp).sort((a, b) => b[1] - a[1])[0];
    return {
      totalMinutes,
      topApp: topApp ? { package: topApp[0], minutes: topApp[1] } : null,
      minutesByApp,
      updatedAt: summary?.occurredAt ?? null,
    };
  }

  /** Latest permission snapshot from the child device. */
  async latestPermissions(familyId: string, deviceId: string) {
    await this.devices.getForFamily(familyId, deviceId);
    const row = await this.prisma.event.findFirst({
      where: { deviceId, type: 'PERMISSION_STATE' },
      orderBy: { occurredAt: 'desc' },
    });
    return {
      permissions:
        (row?.data as { permissions?: Record<string, boolean> } | null)
          ?.permissions ?? null,
      updatedAt: row?.occurredAt ?? null,
    };
  }

  /** Installed apps derived from install/remove events. */
  async installedApps(familyId: string, deviceId: string) {
    await this.devices.getForFamily(familyId, deviceId);
    const events = await this.prisma.event.findMany({
      where: {
        deviceId,
        type: { in: ['APP_INSTALLED', 'APP_REMOVED'] },
      },
      orderBy: { occurredAt: 'asc' },
      take: 5000,
    });
    const apps = new Map<string, { package: string; label?: string }>();
    for (const e of events) {
      const data = e.data as { package?: string; label?: string };
      const pkg = data.package;
      if (!pkg) continue;
      if (e.type === 'APP_INSTALLED') {
        apps.set(pkg, { package: pkg, label: data.label });
      } else {
        apps.delete(pkg);
      }
    }
    return Array.from(apps.values()).sort((a, b) =>
      (a.label ?? a.package).localeCompare(b.label ?? b.package),
    );
  }

  private async fanOutAlerts(
    deviceId: string,
    events: IngestEventsDto['events'],
  ): Promise<void> {
    const installs = events.filter(
      (e) =>
        e.type === 'APP_INSTALLED' &&
        !(e.data as { snapshot?: boolean }).snapshot,
    );
    if (installs.length === 0) return;

    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
      select: { familyId: true, name: true },
    });
    if (!device) return;

    for (const ev of installs) {
      const data = ev.data as { package?: string; label?: string };
      const pkg = data.package ?? 'unknown';
      const label = data.label ?? pkg;
      const recent = await this.prisma.alert.findFirst({
        where: {
          familyId: device.familyId,
          deviceId,
          type: 'NEW_APP',
          createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
          body: { contains: pkg },
        },
      });
      if (recent) continue;
      await this.alerts.create({
        familyId: device.familyId,
        deviceId,
        type: 'NEW_APP',
        title: 'New app installed',
        body: `Child installed a new app: ${label}`,
        data: { package: pkg, label } as Prisma.InputJsonValue,
      });
    }
  }
}
