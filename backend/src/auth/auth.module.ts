import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';

/**
 * Global so any feature module can use JwtAuthGuard / DeviceAuthGuard / TokenService
 * without re-importing. Token signing/verification config lives in TokenService.
 */
@Global()
@Module({
  imports: [JwtModule.register({})],
  controllers: [AuthController],
  providers: [AuthService, TokenService, JwtAuthGuard, DeviceAuthGuard],
  exports: [TokenService, JwtAuthGuard, DeviceAuthGuard],
})
export class AuthModule {}
