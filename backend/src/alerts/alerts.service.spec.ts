import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuditService } from '../audit/audit.service';
import { FcmService } from '../fcm/fcm.service';
import { PrismaService } from '../prisma/prisma.service';
import { AlertsService } from './alerts.service';

describe('AlertsService', () => {
  let service: AlertsService;
  let prisma: {
    alert: { create: jest.Mock; findMany: jest.Mock; findFirst: jest.Mock; update: jest.Mock };
    user: { findMany: jest.Mock };
  };
  let fcm: { sendData: jest.Mock };
  let audit: { log: jest.Mock };

  beforeEach(async () => {
    prisma = {
      alert: {
        create: jest.fn(),
        findMany: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      user: { findMany: jest.fn().mockResolvedValue([]) },
    };
    fcm = { sendData: jest.fn().mockResolvedValue(true) };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const ref = await Test.createTestingModule({
      providers: [
        AlertsService,
        { provide: PrismaService, useValue: prisma },
        { provide: FcmService, useValue: fcm },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();
    service = ref.get(AlertsService);
  });

  it('persists an alert and pushes to every parent token', async () => {
    prisma.alert.create.mockResolvedValue({ id: 'a1', type: 'TAMPER', familyId: 'f1' });
    prisma.user.findMany.mockResolvedValue([
      { fcmToken: 't1' },
      { fcmToken: 't2' },
    ]);

    await service.create({
      familyId: 'f1',
      type: 'TAMPER',
      title: 'x',
      body: 'y',
    });

    expect(fcm.sendData).toHaveBeenCalledTimes(2);
    expect(fcm.sendData).toHaveBeenCalledWith(
      't1',
      expect.objectContaining({ kind: 'alert', alertId: 'a1' }),
      true,
    );
  });

  it('markRead rejects an alert from another family', async () => {
    prisma.alert.findFirst.mockResolvedValue(null);
    await expect(service.markRead('f1', 'nope')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('requestUnblock raises an UNBLOCK_REQUEST alert and audits it', async () => {
    prisma.alert.create.mockResolvedValue({ id: 'a2', type: 'UNBLOCK_REQUEST' });
    const res = await service.requestUnblock('f1', 'd1', {
      appPackage: 'com.instagram.android',
    });
    expect(res.type).toBe('UNBLOCK_REQUEST');
    expect(prisma.alert.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ type: 'UNBLOCK_REQUEST', deviceId: 'd1' }),
      }),
    );
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'unblock_requested' }),
    );
  });
});
