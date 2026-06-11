import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';
import { AppController } from './app.controller';
import { AlertsModule } from './alerts/alerts.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { CommandsModule } from './commands/commands.module';
import { DevicesModule } from './devices/devices.module';
import { EventsModule } from './events/events.module';
import { FcmModule } from './fcm/fcm.module';
import { HeartbeatModule } from './heartbeat/heartbeat.module';
import { LocationsModule } from './locations/locations.module';
import { PairingModule } from './pairing/pairing.module';
import { PoliciesModule } from './policies/policies.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { TamperModule } from './tamper/tamper.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
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
  ],
  controllers: [AppController],
})
export class AppModule {}
