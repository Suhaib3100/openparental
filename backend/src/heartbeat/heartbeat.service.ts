import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { TamperService } from '../tamper/tamper.service';

@Injectable()
export class HeartbeatService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(HeartbeatService.name);
  private readonly ttlSeconds: number;
  private readonly darkAfterSeconds: number;
  private timer?: ReturnType<typeof setInterval>;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly tamper: TamperService,
    config: ConfigService,
  ) {
    const interval = config.get<number>('heartbeat.intervalSeconds') ?? 75;
    const miss = config.get<number>('heartbeat.missGrace') ?? 2;
    this.ttlSeconds = interval * miss;
    this.darkAfterSeconds = interval * miss;
  }

  onModuleInit(): void {
    if (process.env.NODE_ENV === 'test') return; // no background timer under jest
    this.timer = setInterval(() => {
      this.reconcileDarkDevices().catch((e) => this.logger.warn(String(e)));
    }, this.ttlSeconds * 1000);
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  /** Device check-in: refresh presence, mark ONLINE, surface a RECOVERED if dark. */
  async beat(
    familyId: string,
    deviceId: string,
    batteryPct?: number,
  ): Promise<void> {
    await this.redis.setPresence(deviceId, this.ttlSeconds);
    const device = await this.prisma.device.findUnique({
      where: { id: deviceId },
    });
    const wasDark = device?.status === 'DARK';

    await this.prisma.heartbeat.create({ data: { deviceId, batteryPct } });
    await this.prisma.device.update({
      where: { id: deviceId },
      data: {
        status: 'ONLINE',
        batteryPct: batteryPct ?? undefined,
        lastSeenAt: new Date(),
      },
    });
    if (wasDark) {
      await this.tamper.report(familyId, deviceId, 'RECOVERED', 'device reconnected');
    }
  }

  /**
   * "Went dark" detection. Reads device.lastSeenAt from Postgres (NOT Redis), so
   * a Redis restart can never fire a false alert — the regression the eng review
   * flagged as critical.
   */
  async reconcileDarkDevices(): Promise<number> {
    const cutoff = new Date(Date.now() - this.darkAfterSeconds * 1000);
    const stale = await this.prisma.device.findMany({
      where: { status: 'ONLINE', lastSeenAt: { lt: cutoff } },
    });
    for (const d of stale) {
      await this.prisma.device.update({
        where: { id: d.id },
        data: { status: 'DARK' },
      });
      await this.tamper.report(d.familyId, d.id, 'WENT_DARK', 'missed heartbeats');
    }
    return stale.length;
  }
}
