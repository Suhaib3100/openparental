import { Test } from '@nestjs/testing';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsService } from './events.service';

describe('EventsService', () => {
  let service: EventsService;
  let prisma: {
    event: { createMany: jest.Mock; findMany: jest.Mock };
    device: { update: jest.Mock };
  };
  let devices: { getForFamily: jest.Mock };

  beforeEach(async () => {
    prisma = {
      event: { createMany: jest.fn(), findMany: jest.fn() },
      device: { update: jest.fn().mockResolvedValue({}) },
    };
    devices = { getForFamily: jest.fn().mockResolvedValue({ id: 'd1' }) };

    const ref = await Test.createTestingModule({
      providers: [
        EventsService,
        { provide: PrismaService, useValue: prisma },
        { provide: DevicesService, useValue: devices },
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
