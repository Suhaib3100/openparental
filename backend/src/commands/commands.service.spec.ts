import { NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { AuditService } from '../audit/audit.service';
import { DevicesService } from '../devices/devices.service';
import { FcmService } from '../fcm/fcm.service';
import { PrismaService } from '../prisma/prisma.service';
import { CommandsService } from './commands.service';

describe('CommandsService', () => {
  let service: CommandsService;
  let prisma: {
    command: {
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      findFirst: jest.Mock;
      findMany: jest.Mock;
      updateMany: jest.Mock;
    };
  };
  let devices: { getForFamily: jest.Mock };
  let fcm: { sendData: jest.Mock };
  let audit: { log: jest.Mock };

  beforeEach(async () => {
    prisma = {
      command: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        findFirst: jest.fn(),
        findMany: jest.fn(),
        updateMany: jest.fn(),
      },
    };
    devices = {
      getForFamily: jest
        .fn()
        .mockResolvedValue({ id: 'd1', familyId: 'f1', fcmToken: 'tok' }),
    };
    fcm = { sendData: jest.fn().mockResolvedValue(true) };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const ref = await Test.createTestingModule({
      providers: [
        CommandsService,
        { provide: PrismaService, useValue: prisma },
        { provide: DevicesService, useValue: devices },
        { provide: FcmService, useValue: fcm },
        { provide: AuditService, useValue: audit },
        { provide: ConfigService, useValue: { get: () => 300 } },
      ],
    }).compile();
    service = ref.get(CommandsService);
  });

  describe('enqueue', () => {
    it('creates, pushes high-priority FCM for LOCK, and marks SENT', async () => {
      prisma.command.findUnique.mockResolvedValue(null);
      prisma.command.create.mockResolvedValue({
        id: 'c1',
        type: 'LOCK',
        state: 'QUEUED',
      });
      prisma.command.update.mockResolvedValue({ id: 'c1', state: 'SENT' });

      const res = await service.enqueue('f1', 'd1', { type: 'LOCK' as never });

      expect(res.state).toBe('SENT');
      expect(fcm.sendData).toHaveBeenCalledWith(
        'tok',
        expect.objectContaining({ kind: 'command', commandId: 'c1' }),
        true, // LOCK is high priority
      );
      expect(audit.log).toHaveBeenCalled();
    });

    it('is idempotent: an existing key returns the existing command', async () => {
      prisma.command.findUnique.mockResolvedValue({ id: 'c0', state: 'ACKED' });
      const res = await service.enqueue('f1', 'd1', {
        type: 'PING' as never,
        idempotencyKey: 'dup',
      });
      expect(res.id).toBe('c0');
      expect(prisma.command.create).not.toHaveBeenCalled();
    });

    it('stays QUEUED when the device has no FCM token', async () => {
      devices.getForFamily.mockResolvedValue({
        id: 'd1',
        familyId: 'f1',
        fcmToken: null,
      });
      prisma.command.findUnique.mockResolvedValue(null);
      prisma.command.create.mockResolvedValue({ id: 'c1', type: 'PING' });
      prisma.command.update.mockResolvedValue({ id: 'c1', state: 'QUEUED' });

      const res = await service.enqueue('f1', 'd1', { type: 'PING' as never });
      expect(res.state).toBe('QUEUED');
      expect(fcm.sendData).not.toHaveBeenCalled();
    });
  });

  describe('ack', () => {
    it('moves SENT -> ACKED', async () => {
      prisma.command.findFirst.mockResolvedValue({ id: 'c1', state: 'SENT' });
      prisma.command.update.mockResolvedValue({ id: 'c1', state: 'ACKED' });
      const res = await service.ack('d1', 'c1');
      expect(res.state).toBe('ACKED');
    });

    it('is a no-op once terminal (duplicate delivery)', async () => {
      prisma.command.findFirst.mockResolvedValue({ id: 'c1', state: 'DONE' });
      const res = await service.ack('d1', 'c1');
      expect(res.state).toBe('DONE');
      expect(prisma.command.update).not.toHaveBeenCalled();
    });

    it('throws when the command is not the device own', async () => {
      prisma.command.findFirst.mockResolvedValue(null);
      await expect(service.ack('d1', 'nope')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('complete', () => {
    it('marks DONE on success', async () => {
      prisma.command.findFirst.mockResolvedValue({ id: 'c1', state: 'ACKED' });
      prisma.command.update.mockResolvedValue({ id: 'c1', state: 'DONE' });
      const res = await service.complete('d1', 'c1', { result: { ok: true } });
      expect(res.state).toBe('DONE');
    });

    it('marks FAILED when an error is reported', async () => {
      prisma.command.findFirst.mockResolvedValue({ id: 'c1', state: 'ACKED' });
      prisma.command.update.mockResolvedValue({ id: 'c1', state: 'FAILED' });
      const res = await service.complete('d1', 'c1', { error: 'boom' });
      expect(res.state).toBe('FAILED');
      expect(prisma.command.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ state: 'FAILED', error: 'boom' }),
        }),
      );
    });
  });

  describe('pullPending', () => {
    it('expires stale commands then returns the active ones', async () => {
      prisma.command.updateMany.mockResolvedValue({ count: 1 });
      prisma.command.findMany.mockResolvedValue([{ id: 'c1', state: 'QUEUED' }]);
      const res = await service.pullPending('d1');
      expect(prisma.command.updateMany).toHaveBeenCalled();
      expect(res).toHaveLength(1);
    });
  });

  describe('getForFamily', () => {
    it('throws when the command is in another family', async () => {
      prisma.command.findFirst.mockResolvedValue(null);
      await expect(service.getForFamily('f1', 'nope')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
