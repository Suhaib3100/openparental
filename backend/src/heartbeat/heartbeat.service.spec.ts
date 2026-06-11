import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { TamperService } from '../tamper/tamper.service';
import { HeartbeatService } from './heartbeat.service';

describe('HeartbeatService', () => {
  let service: HeartbeatService;
  let prisma: {
    device: { findUnique: jest.Mock; update: jest.Mock; findMany: jest.Mock };
    heartbeat: { create: jest.Mock };
  };
  let redis: { setPresence: jest.Mock };
  let tamper: { report: jest.Mock };

  beforeEach(async () => {
    prisma = {
      device: {
        findUnique: jest.fn(),
        update: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([]),
      },
      heartbeat: { create: jest.fn().mockResolvedValue({}) },
    };
    redis = { setPresence: jest.fn().mockResolvedValue(undefined) };
    tamper = { report: jest.fn().mockResolvedValue({}) };

    const ref = await Test.createTestingModule({
      providers: [
        HeartbeatService,
        { provide: PrismaService, useValue: prisma },
        { provide: RedisService, useValue: redis },
        { provide: TamperService, useValue: tamper },
        {
          provide: ConfigService,
          useValue: { get: (k: string) => (k === 'heartbeat.intervalSeconds' ? 75 : 2) },
        },
      ],
    }).compile();
    service = ref.get(HeartbeatService);
  });

  it('refreshes presence and marks the device ONLINE', async () => {
    prisma.device.findUnique.mockResolvedValue({ id: 'd1', status: 'ONLINE' });
    await service.beat('f1', 'd1', 88);
    expect(redis.setPresence).toHaveBeenCalledWith('d1', 150); // 75 * 2
    expect(prisma.device.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'ONLINE', batteryPct: 88 }),
      }),
    );
    expect(tamper.report).not.toHaveBeenCalled();
  });

  it('emits RECOVERED when a dark device checks back in', async () => {
    prisma.device.findUnique.mockResolvedValue({ id: 'd1', status: 'DARK' });
    await service.beat('f1', 'd1');
    expect(tamper.report).toHaveBeenCalledWith(
      'f1',
      'd1',
      'RECOVERED',
      expect.any(String),
    );
  });

  it('reconciler marks stale devices DARK and raises WENT_DARK', async () => {
    prisma.device.findMany.mockResolvedValue([{ id: 'd1', familyId: 'f1' }]);
    const count = await service.reconcileDarkDevices();
    expect(count).toBe(1);
    expect(prisma.device.update).toHaveBeenCalledWith({
      where: { id: 'd1' },
      data: { status: 'DARK' },
    });
    expect(tamper.report).toHaveBeenCalledWith(
      'f1',
      'd1',
      'WENT_DARK',
      expect.any(String),
    );
  });
});
