import { Injectable } from '@nestjs/common';
import { AlertType, TamperEvent, TamperKind } from '@prisma/client';
import { AlertsService } from '../alerts/alerts.service';
import { AuditService } from '../audit/audit.service';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { ReportTamperDto } from './dto/report-tamper.dto';

const TITLES: Record<TamperKind, string> = {
  ACCESSIBILITY_OFF: 'Accessibility turned off',
  ADMIN_OFF: 'Device admin removed',
  VPN_OFF: 'Filter VPN turned off',
  VPN_EVICTED: 'Filter VPN replaced by another VPN',
  BATTERY_OPT_OFF: 'Battery optimization re-enabled',
  FORCE_STOP: 'App was force-stopped',
  WENT_DARK: 'Device went offline',
  RECOVERED: 'Device back online',
};

@Injectable()
export class TamperService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly alerts: AlertsService,
    private readonly devices: DevicesService,
    private readonly audit: AuditService,
  ) {}

  /**
   * Record a tamper event and (for everything except RECOVERED) raise an alert.
   * Called both by the device (it noticed a layer was disabled) and by the
   * heartbeat reconciler (WENT_DARK / RECOVERED).
   */
  async report(
    familyId: string,
    deviceId: string,
    kind: TamperKind,
    detail?: string,
    occurredAt?: Date,
  ): Promise<TamperEvent> {
    const event = await this.prisma.tamperEvent.create({
      data: { deviceId, kind, detail, occurredAt: occurredAt ?? new Date() },
    });
    if (kind !== 'RECOVERED') {
      const type: AlertType = kind === 'WENT_DARK' ? 'DEVICE_OFFLINE' : 'TAMPER';
      await this.alerts.create({
        familyId,
        deviceId,
        type,
        title: TITLES[kind],
        body: detail ?? TITLES[kind],
      });
      await this.audit.log({
        familyId,
        actor: deviceId,
        action: `tamper_${kind.toLowerCase()}`,
      });
    }
    return event;
  }

  reportFromDevice(
    familyId: string,
    deviceId: string,
    dto: ReportTamperDto,
  ): Promise<TamperEvent> {
    return this.report(
      familyId,
      deviceId,
      dto.kind,
      dto.detail,
      dto.occurredAt ? new Date(dto.occurredAt) : undefined,
    );
  }

  async listForFamilyDevice(
    familyId: string,
    deviceId: string,
    limit = 100,
  ): Promise<TamperEvent[]> {
    await this.devices.getForFamily(familyId, deviceId); // ownership
    return this.prisma.tamperEvent.findMany({
      where: { deviceId },
      orderBy: { occurredAt: 'desc' },
      take: Math.min(limit, 500),
    });
  }
}
