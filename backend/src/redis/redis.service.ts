import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

const presenceKey = (deviceId: string) => `presence:${deviceId}`;

/**
 * Thin Redis wrapper. Presence keys carry the device heartbeat: each heartbeat
 * sets `presence:<id>` with a TTL of (interval * missGrace). When the key
 * expires, the device is "dark" — the HeartbeatModule reconciles expiries
 * against Postgres so a Redis restart never fires a false "went dark" alert.
 */
@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client!: Redis;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const url = this.config.get<string>('redisUrl') ?? 'redis://localhost:6379';
    this.client = new Redis(url, { maxRetriesPerRequest: null });
  }

  async onModuleDestroy(): Promise<void> {
    await this.client?.quit();
  }

  get raw(): Redis {
    return this.client;
  }

  async setPresence(deviceId: string, ttlSeconds: number): Promise<void> {
    await this.client.set(presenceKey(deviceId), Date.now().toString(), 'EX', ttlSeconds);
  }

  async isPresent(deviceId: string): Promise<boolean> {
    return (await this.client.exists(presenceKey(deviceId))) === 1;
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (ttlSeconds) {
      await this.client.set(key, value, 'EX', ttlSeconds);
    } else {
      await this.client.set(key, value);
    }
  }

  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  async del(key: string): Promise<void> {
    await this.client.del(key);
  }
}
