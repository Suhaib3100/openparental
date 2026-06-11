import { Test } from '@nestjs/testing';
import { AuditService } from '../audit/audit.service';
import { CommandsService } from '../commands/commands.service';
import { PrismaService } from '../prisma/prisma.service';
import { PoliciesService } from './policies.service';

describe('PoliciesService', () => {
  let service: PoliciesService;
  let prisma: {
    policy: {
      findFirst: jest.Mock;
      findMany: jest.Mock;
      updateMany: jest.Mock;
      create: jest.Mock;
    };
    device: { findMany: jest.Mock };
  };
  let commands: { enqueue: jest.Mock };
  let audit: { log: jest.Mock };

  beforeEach(async () => {
    prisma = {
      policy: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
        updateMany: jest.fn(),
        create: jest.fn(),
      },
      device: { findMany: jest.fn().mockResolvedValue([]) },
    };
    commands = { enqueue: jest.fn().mockResolvedValue({}) };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const ref = await Test.createTestingModule({
      providers: [
        PoliciesService,
        { provide: PrismaService, useValue: prisma },
        { provide: CommandsService, useValue: commands },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();
    service = ref.get(PoliciesService);
  });

  it('getActive returns the active policy', async () => {
    prisma.policy.findFirst.mockResolvedValue({ id: 'p1', version: 2, active: true });
    const res = await service.getActive('f1');
    expect(res?.version).toBe(2);
    expect(prisma.policy.findFirst).toHaveBeenCalledWith({
      where: { familyId: 'f1', active: true },
      orderBy: { version: 'desc' },
    });
  });

  it('update bumps the version, deactivates the old, and pushes to every device', async () => {
    prisma.policy.findFirst.mockResolvedValue({ id: 'p2', version: 2 });
    prisma.policy.updateMany.mockResolvedValue({ count: 1 });
    prisma.policy.create.mockResolvedValue({ id: 'p3', version: 3, active: true });
    prisma.device.findMany.mockResolvedValue([{ id: 'd1' }, { id: 'd2' }]);

    const res = await service.update('f1', { blockedApps: ['com.x'] });

    expect(res.version).toBe(3);
    expect(prisma.policy.updateMany).toHaveBeenCalledWith({
      where: { familyId: 'f1', active: true },
      data: { active: false },
    });
    expect(commands.enqueue).toHaveBeenCalledTimes(2);
    expect(commands.enqueue).toHaveBeenCalledWith(
      'f1',
      'd1',
      expect.objectContaining({ type: 'SET_POLICY' }),
    );
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'policy_updated' }),
    );
  });

  it('starts at version 1 when no policy exists yet', async () => {
    prisma.policy.findFirst.mockResolvedValue(null);
    prisma.policy.updateMany.mockResolvedValue({ count: 0 });
    prisma.policy.create.mockResolvedValue({ id: 'p1', version: 1 });
    prisma.device.findMany.mockResolvedValue([]);

    await service.update('f1', {});
    expect(prisma.policy.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ version: 1 }) }),
    );
  });
});
