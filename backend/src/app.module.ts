import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';
import { AppController } from './app.controller';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { CommandsModule } from './commands/commands.module';
import { DevicesModule } from './devices/devices.module';
import { FcmModule } from './fcm/fcm.module';
import { PairingModule } from './pairing/pairing.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    PrismaModule,
    RedisModule,
    AuditModule,
    FcmModule,
    AuthModule,
    DevicesModule,
    PairingModule,
    CommandsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
