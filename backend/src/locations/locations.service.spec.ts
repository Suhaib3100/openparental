import { Test } from '@nestjs/testing';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { LocationsService } from './locations.service';

describe('LocationsService', () => {
  let service: LocationsService;
  let prisma: {
    location: { create: jest.Mock; findFirst: jest.Mock; findMany: jest.Mock };
    device: { update: jest.Mock };
  };
  let devices: { getForFamily: jest.Mock };

  beforeEach(async () => {
    prisma = {
      location: {
        create: jest.fn().mockResolvedValue({ id: 'l1' }),
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
      device: { update: jest.fn().mockResolvedValue({}) },
    };
    devices = { getForFamily: jest.fn().mockResolvedValue({ id: 'd1' }) };

    const ref = await Test.createTestingModule({
      providers: [
        LocationsService,
        { provide: PrismaService, useValue: prisma },
        { provide: DevicesService, useValue: devices },
      ],
    }).compile();
    service = ref.get(LocationsService);
  });

  it('ingest stores a fix and touches lastSeen', async () => {
    const res = await service.ingest('d1', { lat: 1.5, lng: 2.5 });
    expect(res.id).toBe('l1');
    expect(prisma.location.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ deviceId: 'd1', lat: 1.5, lng: 2.5 }),
      }),
    );
    expect(prisma.device.update).toHaveBeenCalled();
  });

  it('latest enforces ownership', async () => {
    await service.latest('f1', 'd1');
    expect(devices.getForFamily).toHaveBeenCalledWith('f1', 'd1');
  });

  it('history enforces ownership', async () => {
    await service.history('f1', 'd1');
    expect(devices.getForFamily).toHaveBeenCalledWith('f1', 'd1');
  });
});
