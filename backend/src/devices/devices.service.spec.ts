import { NotFoundException, UnauthorizedException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuditService } from '../audit/audit.service';
import { sha256 } from '../common/hash.util';
import { PrismaService } from '../prisma/prisma.service';
import { TokenService } from '../auth/token.service';
import { DevicesService } from './devices.service';

describe('DevicesService', () => {
  let service: DevicesService;
  let prisma: {
    device: {
      create: jest.Mock;
      findMany: jest.Mock;
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
  };
  let tokens: { signDevice: jest.Mock };
  let audit: { log: jest.Mock };

  const device = {
    id: 'd1',
    familyId: 'f1',
    name: 'Phone',
    model: 'Pixel',
    secretHash: sha256('secret'),
    status: 'ONLINE',
  };

  beforeEach(async () => {
    prisma = {
      device: {
        create: jest.fn(),
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
    };
    tokens = { signDevice: jest.fn().mockResolvedValue('device-token') };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const ref = await Test.createTestingModule({
      providers: [
        DevicesService,
        { provide: PrismaService, useValue: prisma },
        { provide: TokenService, useValue: tokens },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();
    service = ref.get(DevicesService);
  });

  it('createForPairing stores a hashed secret and returns the plaintext once', async () => {
    prisma.device.create.mockImplementation(({ data }) =>
      Promise.resolve({ id: 'd1', ...data }),
    );
    const res = await service.createForPairing('f1', {
      model: 'Pixel',
      manufacturer: 'Google',
    });
    expect(res.device.familyId).toBe('f1');
    expect(typeof res.deviceSecret).toBe('string');
    expect(res.device.secretHash).toBe(sha256(res.deviceSecret));
  });

  it('listForFamily scopes the query by familyId', async () => {
    prisma.device.findMany.mockResolvedValue([device]);
    await service.listForFamily('f1');
    expect(prisma.device.findMany).toHaveBeenCalledWith({
      where: { familyId: 'f1' },
      orderBy: { createdAt: 'asc' },
    });
  });

  it('getForFamily rejects a device belonging to another family', async () => {
    prisma.device.findFirst.mockResolvedValue(null);
    await expect(service.getForFamily('f1', 'other')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('rename enforces ownership before updating', async () => {
    prisma.device.findFirst.mockResolvedValue(device);
    prisma.device.update.mockResolvedValue({ ...device, name: 'New name' });
    const res = await service.rename('f1', 'd1', 'New name');
    expect(res.name).toBe('New name');
  });

  it('remove deletes the device and writes an audit entry', async () => {
    prisma.device.findFirst.mockResolvedValue(device);
    prisma.device.delete.mockResolvedValue(device);
    await service.remove('f1', 'd1');
    expect(prisma.device.delete).toHaveBeenCalledWith({ where: { id: 'd1' } });
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'device_removed' }),
    );
  });

  it('reauth returns a fresh token for a valid secret', async () => {
    prisma.device.findUnique.mockResolvedValue(device);
    const res = await service.reauth('d1', 'secret');
    expect(res.deviceToken).toBe('device-token');
  });

  it('reauth rejects an invalid secret', async () => {
    prisma.device.findUnique.mockResolvedValue(device);
    await expect(service.reauth('d1', 'wrong')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
