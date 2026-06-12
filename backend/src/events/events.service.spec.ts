import { Test } from '@nestjs/testing';
import { AlertsService } from '../alerts/alerts.service';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsService } from './events.service';

describe('EventsService', () => {
  let service: EventsService;
  let prisma: {
    event: { createMany: jest.Mock; findMany: jest.Mock; findFirst: jest.Mock };
    device: { update: jest.Mock; findUnique: jest.Mock };
    alert: { findFirst: jest.Mock };
  };
  let devices: { getForFamily: jest.Mock };
  let alerts: { create: jest.Mock };

  beforeEach(async () => {
    prisma = {
      event: {
        createMany: jest.fn(),
        findMany: jest.fn(),
        findFirst: jest.fn(),
      },
      device: { update: jest.fn().mockResolvedValue({}), findUnique: jest.fn() },
      alert: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    devices = { getForFamily: jest.fn().mockResolvedValue({ id: 'd1' }) };
    alerts = { create: jest.fn().mockResolvedValue({}) };

    const ref = await Test.createTestingModule({
      providers: [
        EventsService,
        { provide: PrismaService, useValue: prisma },
        { provide: DevicesService, useValue: devices },
        { provide: AlertsService, useValue: alerts },
      ],
    }).compile();
    service = ref.get(EventsService);
  });

  it('bulk-inserts a batch and returns the count', async () => {
    prisma.event.createMany.mockResolvedValue({ count: 2 });
    const res = await service.ingestBatch('d1', {
      events: [
        { type: 'APP_FOREGROUND' as never, data: { pkg: 'a' }, occurredAt: '2026-06-12T00:00:00Z' },
        { type: 'SCREEN_TIME' as never, data: { mins: 5 }, occurredAt: '2026-06-12T00:01:00Z' },
      ],
    });
    expect(res.count).toBe(2);
    expect(prisma.event.createMany).toHaveBeenCalledWith({
      data: expect.arrayContaining([
        expect.objectContaining({ deviceId: 'd1', type: 'APP_FOREGROUND' }),
      ]),
    });
  });

  it('raises NEW_APP alert on APP_INSTALLED (not snapshots)', async () => {
    prisma.event.createMany.mockResolvedValue({ count: 1 });
    prisma.device.findUnique.mockResolvedValue({
      familyId: 'f1',
      name: 'Phone',
    });
    await service.ingestBatch('d1', {
      events: [
        {
          type: 'APP_INSTALLED' as never,
          data: { package: 'com.example.game', label: 'Example Game' },
          occurredAt: '2026-06-12T00:00:00Z',
        },
      ],
    });
    expect(alerts.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'NEW_APP', deviceId: 'd1' }),
    );
  });

  it('no-ops on an empty batch', async () => {
    const res = await service.ingestBatch('d1', { events: [] });
    expect(res.count).toBe(0);
    expect(prisma.event.createMany).not.toHaveBeenCalled();
  });

  it('listForFamilyDevice enforces ownership', async () => {
    prisma.event.findMany.mockResolvedValue([]);
    await service.listForFamilyDevice('f1', 'd1');
    expect(devices.getForFamily).toHaveBeenCalledWith('f1', 'd1');
  });
});
