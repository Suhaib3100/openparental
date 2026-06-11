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
