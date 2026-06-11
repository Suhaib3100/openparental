import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface AuditEntry {
  familyId?: string | null;
  actor: string; // userId | deviceId | "system"
  action: string;
  data?: Prisma.InputJsonValue;
}

/** Append-only audit log. Every privileged action lands here. */
@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(entry: AuditEntry): Promise<void> {
    await this.prisma.auditLog.create({
      data: {
        familyId: entry.familyId ?? null,
        actor: entry.actor,
        action: entry.action,
        data: entry.data,
      },
    });
  }
}
