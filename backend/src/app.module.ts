import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import configuration from './config/configuration';
import { AppController } from './app.controller';
import { AlertsModule } from './alerts/alerts.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { CommandsModule } from './commands/commands.module';
import { ContentModule } from './content/content.module';
import { DevicesModule } from './devices/devices.module';
import { EventsModule } from './events/events.module';
import { FcmModule } from './fcm/fcm.module';
import { HeartbeatModule } from './heartbeat/heartbeat.module';
import { LocationsModule } from './locations/locations.module';
import { PairingModule } from './pairing/pairing.module';
import { PhotosModule } from './photos/photos.module';
import { PoliciesModule } from './policies/policies.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { TamperModule } from './tamper/tamper.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    // Applied per route with @UseGuards(ThrottlerGuard) on credential endpoints
    // only, so heartbeats and event uploads from child devices are never throttled.
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          name: 'auth',
          ttl: 60_000,
          limit: config.get<number>('rateLimit.authPerMinute') ?? 10,
        },
      ],
    }),
    PrismaModule,
    RedisModule,
    AuditModule,
    FcmModule,
    AlertsModule,
    AuthModule,
    DevicesModule,
    PairingModule,
    CommandsModule,
    PoliciesModule,
    EventsModule,
    TamperModule,
    HeartbeatModule,
    LocationsModule,
    ContentModule,
    PhotosModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
