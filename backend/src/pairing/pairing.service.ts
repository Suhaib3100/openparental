import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { pairingCode, randomToken } from '../common/hash.util';
import { PrismaService } from '../prisma/prisma.service';
import { TokenService } from '../auth/token.service';
import { DevicesService } from '../devices/devices.service';
import { ClaimPairingDto } from './dto/claim-pairing.dto';
import { CreatePairingDto } from './dto/create-pairing.dto';

const PAIRING_TTL_MS = 15 * 60 * 1000; // 15 minutes

export interface CreatedPairing {
  id: string;
  code: string;
  qrToken: string;
  expiresAt: Date;
}

export interface ClaimResult {
  deviceId: string;
  deviceToken: string;
  deviceSecret: string;
}

@Injectable()
export class PairingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly devices: DevicesService,
    private readonly audit: AuditService,
  ) {}

  /** Parent creates a pairing slot; returns the code + QR token to display. */
  async create(familyId: string, dto: CreatePairingDto): Promise<CreatedPairing> {
    const pairing = await this.prisma.pairing.create({
      data: {
        familyId,
        code: pairingCode(),
        qrToken: randomToken(),
        deviceName: dto.deviceName,
        status: 'PENDING',
        expiresAt: new Date(Date.now() + PAIRING_TTL_MS),
      },
    });
    return {
      id: pairing.id,
      code: pairing.code,
      qrToken: pairing.qrToken,
      expiresAt: pairing.expiresAt,
    };
  }

  /** Device claims a pairing (token = QR token or code). Mints a device token. */
  async claim(dto: ClaimPairingDto): Promise<ClaimResult> {
    const pairing = await this.prisma.pairing.findFirst({
      where: { OR: [{ qrToken: dto.token }, { code: dto.token }] },
    });
    if (!pairing) throw new NotFoundException('pairing not found');
    if (pairing.status !== 'PENDING') {
      throw new BadRequestException('pairing already used');
    }
    if (pairing.expiresAt.getTime() < Date.now()) {
      await this.prisma.pairing.update({
        where: { id: pairing.id },
        data: { status: 'EXPIRED' },
      });
      throw new BadRequestException('pairing expired');
    }

    const { device, deviceSecret } = await this.devices.createForPairing(
      pairing.familyId,
      { ...dto, deviceName: dto.deviceName ?? pairing.deviceName ?? undefined },
    );
    const deviceToken = await this.tokens.signDevice(device.id, pairing.familyId);

    await this.prisma.pairing.update({
      where: { id: pairing.id },
      data: { status: 'CLAIMED', claimedDeviceId: device.id },
    });
    await this.audit.log({
      familyId: pairing.familyId,
      actor: device.id,
      action: 'device_paired',
      data: { pairingId: pairing.id, model: device.model ?? undefined },
    });

    return { deviceId: device.id, deviceToken, deviceSecret };
  }

  /** Parent polls pairing status while the child sets up the device. */
  async getStatus(familyId: string, id: string) {
    const pairing = await this.prisma.pairing.findFirst({
      where: { id, familyId },
    });
    if (!pairing) throw new NotFoundException('pairing not found');
    return {
      id: pairing.id,
      status: pairing.status,
      claimedDeviceId: pairing.claimedDeviceId,
      expiresAt: pairing.expiresAt,
    };
  }
}
