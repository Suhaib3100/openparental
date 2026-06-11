import { Injectable, NotFoundException } from '@nestjs/common';
import { Alert, AlertType, Prisma } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { FcmService } from '../fcm/fcm.service';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUnblockDto } from './dto/request-unblock.dto';

export interface CreateAlertInput {
  familyId: string;
  deviceId?: string | null;
  type: AlertType;
  title: string;
  body: string;
  data?: Prisma.InputJsonValue;
}

@Injectable()
export class AlertsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
    private readonly audit: AuditService,
  ) {}

  /** Persist an alert and fan it out to every parent's FCM token. */
  async create(input: CreateAlertInput): Promise<Alert> {
    const alert = await this.prisma.alert.create({
      data: {
        familyId: input.familyId,
        deviceId: input.deviceId ?? null,
        type: input.type,
        title: input.title,
        body: input.body,
        data: input.data,
      },
    });
    await this.pushToParents(input.familyId, alert);
    return alert;
  }

  listForFamily(familyId: string, unreadOnly = false): Promise<Alert[]> {
    return this.prisma.alert.findMany({
      where: { familyId, ...(unreadOnly ? { readAt: null } : {}) },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async markRead(familyId: string, id: string): Promise<Alert> {
    const alert = await this.prisma.alert.findFirst({ where: { id, familyId } });
    if (!alert) throw new NotFoundException('alert not found');
    return this.prisma.alert.update({
      where: { id },
      data: { readAt: new Date() },
    });
  }

  /** Child requests an app/site be unblocked -> alert in the parent feed. */
  async requestUnblock(
    familyId: string,
    deviceId: string,
    dto: RequestUnblockDto,
  ): Promise<Alert> {
    const alert = await this.create({
      familyId,
      deviceId,
      type: 'UNBLOCK_REQUEST',
      title: 'Unblock request',
      body: dto.reason ?? dto.appPackage ?? 'Your child asked to unblock something.',
      data: { appPackage: dto.appPackage, reason: dto.reason } as Prisma.InputJsonValue,
    });
    await this.audit.log({
      familyId,
      actor: deviceId,
      action: 'unblock_requested',
      data: { appPackage: dto.appPackage },
    });
    return alert;
  }

  private async pushToParents(familyId: string, alert: Alert): Promise<void> {
    const users = await this.prisma.user.findMany({
      where: { familyId, fcmToken: { not: null } },
      select: { fcmToken: true },
    });
    await Promise.all(
      users.map((u) =>
        u.fcmToken
          ? this.fcm.sendData(
              u.fcmToken,
              { kind: 'alert', alertId: alert.id, type: alert.type },
              true,
            )
          : Promise.resolve(false),
      ),
    );
  }
}
