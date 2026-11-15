import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AnyPayload } from '../common/types';

@Injectable()
export class TokenService {
  private readonly secret: string;
  private readonly accessTtl: number;
  private readonly refreshTtl: number;
  private readonly deviceTtl: number;

  constructor(
    private readonly jwt: JwtService,
    config: ConfigService,
  ) {
    this.secret = config.get<string>('jwt.secret') ?? 'dev-secret-change-me';
    // Every token type (parent, refresh, device) is signed with this secret.
    // A guessable secret in production lets anyone mint tokens for any family,
    // so refuse to boot instead of silently using the dev default.
    const isProd = config.get<string>('nodeEnv') === 'production';
    if (isProd && (this.secret.length < 32 || /change-me/.test(this.secret))) {
      throw new Error(
        'JWT_SECRET must be set to a random string of 32+ characters in production',
      );
    }
    this.accessTtl = config.get<number>('jwt.accessTtl') ?? 900;
    this.refreshTtl = config.get<number>('jwt.refreshTtl') ?? 2592000;
    this.deviceTtl = config.get<number>('jwt.deviceTtl') ?? 31536000;
  }

  signAccess(userId: string, familyId: string, role: string): Promise<string> {
    return this.jwt.signAsync(
      { sub: userId, fid: familyId, role, typ: 'access' },
      { secret: this.secret, expiresIn: this.accessTtl },
    );
  }

  signRefresh(userId: string, familyId: string): Promise<string> {
    return this.jwt.signAsync(
      { sub: userId, fid: familyId, typ: 'refresh' },
      { secret: this.secret, expiresIn: this.refreshTtl },
    );
  }

  signDevice(deviceId: string, familyId: string): Promise<string> {
    return this.jwt.signAsync(
      { sub: deviceId, fid: familyId, typ: 'device' },
      { secret: this.secret, expiresIn: this.deviceTtl },
    );
  }

  verify(token: string): Promise<AnyPayload> {
    return this.jwt.verifyAsync<AnyPayload>(token, { secret: this.secret });
  }
}
