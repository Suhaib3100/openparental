import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Device } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { randomToken, safeEqual, sha256 } from '../common/hash.util';
import { PrismaService } from '../prisma/prisma.service';
import { TokenService } from '../auth/token.service';
import { DeviceSelfUpdateDto } from './dto/device-self-update.dto';

export interface ClaimDeviceInput {
  deviceName?: string;
  manufacturer?: string;
  model?: string;
  osVersion?: string;
  appVersion?: string;
  fcmToken?: string;
}

@Injectable()
export class DevicesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
    private readonly audit: AuditService,
  ) {}

  /** Called by PairingService.claim — creates the device and returns its secret. */
  async createForPairing(
    familyId: string,
    input: ClaimDeviceInput,
  ): Promise<{ device: Device; deviceSecret: string }> {
    const deviceSecret = randomToken();
    const device = await this.prisma.device.create({
      data: {
        familyId,
        name: input.deviceName ?? input.model ?? 'Child device',
        manufacturer: input.manufacturer,
        model: input.model,
        osVersion: input.osVersion,
        appVersion: input.appVersion,
        fcmToken: input.fcmToken,
        secretHash: sha256(deviceSecret),
        status: 'ONLINE',
        lastSeenAt: new Date(),
      },
    });
    return { device, deviceSecret };
  }

  listForFamily(familyId: string): Promise<Device[]> {
    return this.prisma.device.findMany({
      where: { familyId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getForFamily(familyId: string, id: string): Promise<Device> {
    const device = await this.prisma.device.findFirst({
      where: { id, familyId },
    });
    if (!device) throw new NotFoundException('device not found');
    return device;
  }

  async rename(familyId: string, id: string, name: string): Promise<Device> {
    await this.getForFamily(familyId, id); // enforce ownership
    return this.prisma.device.update({ where: { id }, data: { name } });
  }

  async remove(familyId: string, id: string): Promise<void> {
    await this.getForFamily(familyId, id);
    await this.prisma.device.delete({ where: { id } });
    await this.audit.log({
      familyId,
      actor: 'parent',
      action: 'device_removed',
      data: { deviceId: id },
    });
  }

  async getSelf(deviceId: string): Promise<Device> {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });
    if (!device) throw new NotFoundException('device not found');
    return device;
  }

  selfUpdate(deviceId: string, dto: DeviceSelfUpdateDto): Promise<Device> {
    return this.prisma.device.update({
      where: { id: deviceId },
      data: {
        batteryPct: dto.batteryPct,
        osVersion: dto.osVersion,
        appVersion: dto.appVersion,
        fcmToken: dto.fcmToken,
        lastSeenAt: new Date(),
      },
    });
  }

  /** Re-mint a device token from the deviceId + secret (token lost / rotated). */
  async reauth(
    deviceId: string,
    secret: string,
  ): Promise<{ deviceId: string; deviceToken: string }> {
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });
    if (!device || !safeEqual(sha256(secret), device.secretHash)) {
      throw new UnauthorizedException('invalid device credentials');
    }
    const deviceToken = await this.tokens.signDevice(device.id, device.familyId);
    return { deviceId: device.id, deviceToken };
  }
}
