import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { safeEqual, sha256 } from '../common/hash.util';
import { TokenService } from './token.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';

const BCRYPT_ROUNDS = 10;

export interface AuthResult {
  accessToken: string;
  refreshToken: string;
  user: { id: string; email: string; familyId: string; role: string };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokenService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResult> {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (existing) throw new ConflictException('email already registered');

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        family: { create: { name: dto.familyName ?? `${dto.email}'s family` } },
      },
    });
    return this.issue(user);
  }

  async login(dto: LoginDto): Promise<AuthResult> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user) throw new UnauthorizedException('invalid credentials');

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('invalid credentials');

    return this.issue(user);
  }

  async refresh(dto: RefreshDto): Promise<AuthResult> {
    let payload;
    try {
      payload = await this.tokens.verify(dto.refreshToken);
    } catch {
      throw new UnauthorizedException('invalid refresh token');
    }
    if (payload.typ !== 'refresh') {
      throw new UnauthorizedException('wrong token type');
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || !user.refreshTokenHash) {
      throw new UnauthorizedException('refresh token revoked');
    }
    if (!safeEqual(sha256(dto.refreshToken), user.refreshTokenHash)) {
      throw new UnauthorizedException('refresh token mismatch');
    }
    return this.issue(user);
  }

  async logout(userId: string): Promise<void> {
    await this.prisma.user.update({
      where: { id: userId },
      data: { refreshTokenHash: null },
    });
  }

  /** Issue an access+refresh pair and persist the (rotated) refresh hash. */
  private async issue(user: {
    id: string;
    email: string;
    familyId: string;
    role: string;
  }): Promise<AuthResult> {
    const accessToken = await this.tokens.signAccess(
      user.id,
      user.familyId,
      user.role,
    );
    const refreshToken = await this.tokens.signRefresh(user.id, user.familyId);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { refreshTokenHash: sha256(refreshToken) },
    });
    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        familyId: user.familyId,
        role: user.role,
      },
    };
  }
}
