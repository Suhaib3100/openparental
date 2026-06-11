import { Test } from '@nestjs/testing';
import { AlertsService } from '../alerts/alerts.service';
import { AuditService } from '../audit/audit.service';
import { DevicesService } from '../devices/devices.service';
import { PrismaService } from '../prisma/prisma.service';
import { TamperService } from './tamper.service';

describe('TamperService', () => {
  let service: TamperService;
  let prisma: { tamperEvent: { create: jest.Mock; findMany: jest.Mock } };
  let alerts: { create: jest.Mock };
  let devices: { getForFamily: jest.Mock };
  let audit: { log: jest.Mock };

  beforeEach(async () => {
    prisma = {
      tamperEvent: {
        create: jest.fn().mockResolvedValue({ id: 't1' }),
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    alerts = { create: jest.fn().mockResolvedValue({ id: 'a1' }) };
    devices = { getForFamily: jest.fn().mockResolvedValue({ id: 'd1' }) };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const ref = await Test.createTestingModule({
      providers: [
        TamperService,
        { provide: PrismaService, useValue: prisma },
        { provide: AlertsService, useValue: alerts },
        { provide: DevicesService, useValue: devices },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();
    service = ref.get(TamperService);
  });

  it('raises a TAMPER alert for a disable event', async () => {
    await service.report('f1', 'd1', 'ACCESSIBILITY_OFF', 'user toggled it');
    expect(prisma.tamperEvent.create).toHaveBeenCalled();
    expect(alerts.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'TAMPER', deviceId: 'd1' }),
    );
    expect(audit.log).toHaveBeenCalled();
  });

  it('uses a DEVICE_OFFLINE alert for WENT_DARK', async () => {
    await service.report('f1', 'd1', 'WENT_DARK');
    expect(alerts.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'DEVICE_OFFLINE' }),
    );
  });

  it('records RECOVERED without raising an alert (no noise)', async () => {
    await service.report('f1', 'd1', 'RECOVERED');
    expect(prisma.tamperEvent.create).toHaveBeenCalled();
    expect(alerts.create).not.toHaveBeenCalled();
    expect(audit.log).not.toHaveBeenCalled();
  });

  it('listForFamilyDevice enforces ownership', async () => {
    await service.listForFamilyDevice('f1', 'd1');
    expect(devices.getForFamily).toHaveBeenCalledWith('f1', 'd1');
  });
});
