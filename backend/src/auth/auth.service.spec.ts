import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { sha256 } from '../common/hash.util';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';

jest.mock('bcrypt');

describe('AuthService', () => {
  let service: AuthService;
  let prisma: {
    user: { findUnique: jest.Mock; create: jest.Mock; update: jest.Mock };
  };
  let tokens: {
    signAccess: jest.Mock;
    signRefresh: jest.Mock;
    signDevice: jest.Mock;
    verify: jest.Mock;
  };

  const sampleUser = {
    id: 'u1',
    email: 'parent@example.com',
    familyId: 'f1',
    role: 'PARENT',
    passwordHash: 'stored-hash',
    refreshTokenHash: null as string | null,
  };

  beforeEach(async () => {
    prisma = {
      user: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
    };
    tokens = {
      signAccess: jest.fn().mockResolvedValue('access-token'),
      signRefresh: jest.fn().mockResolvedValue('refresh-token'),
      signDevice: jest.fn(),
      verify: jest.fn(),
    };

    (bcrypt.hash as jest.Mock).mockResolvedValue('new-hash');
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: TokenService, useValue: tokens },
      ],
    }).compile();
    service = moduleRef.get(AuthService);
  });

  describe('register', () => {
    it('creates a family + user and returns a token pair', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({ ...sampleUser });
      prisma.user.update.mockResolvedValue({ ...sampleUser });

      const result = await service.register({
        email: sampleUser.email,
        password: 'longenough',
      });

      expect(result.accessToken).toBe('access-token');
      expect(result.refreshToken).toBe('refresh-token');
      expect(result.user).toEqual({
        id: 'u1',
        email: sampleUser.email,
        familyId: 'f1',
        role: 'PARENT',
      });
      // refresh hash is persisted as a sha256 of the issued token
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { refreshTokenHash: sha256('refresh-token') },
      });
    });

    it('rejects a duplicate email', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...sampleUser });
      await expect(
        service.register({ email: sampleUser.email, password: 'longenough' }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.user.create).not.toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('returns tokens for valid credentials', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...sampleUser });
      prisma.user.update.mockResolvedValue({ ...sampleUser });
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.login({
        email: sampleUser.email,
        password: 'longenough',
      });
      expect(result.accessToken).toBe('access-token');
    });

    it('rejects an unknown user', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      await expect(
        service.login({ email: 'nope@example.com', password: 'x' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects a wrong password', async () => {
      prisma.user.findUnique.mockResolvedValue({ ...sampleUser });
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);
      await expect(
        service.login({ email: sampleUser.email, password: 'wrong' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    const validRefresh = 'valid-refresh-token';

    it('rotates the token pair when the refresh token matches', async () => {
      tokens.verify.mockResolvedValue({ sub: 'u1', fid: 'f1', typ: 'refresh' });
      prisma.user.findUnique.mockResolvedValue({
        ...sampleUser,
        refreshTokenHash: sha256(validRefresh),
      });
      prisma.user.update.mockResolvedValue({ ...sampleUser });

      const result = await service.refresh({ refreshToken: validRefresh });
      expect(result.accessToken).toBe('access-token');
    });

    it('rejects an unverifiable token', async () => {
      tokens.verify.mockRejectedValue(new Error('bad'));
      await expect(
        service.refresh({ refreshToken: 'garbage' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects a non-refresh token type', async () => {
      tokens.verify.mockResolvedValue({ sub: 'u1', fid: 'f1', typ: 'access' });
      await expect(
        service.refresh({ refreshToken: 'an-access-token' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects when the stored refresh hash is revoked (null)', async () => {
      tokens.verify.mockResolvedValue({ sub: 'u1', fid: 'f1', typ: 'refresh' });
      prisma.user.findUnique.mockResolvedValue({
        ...sampleUser,
        refreshTokenHash: null,
      });
      await expect(
        service.refresh({ refreshToken: validRefresh }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects when the refresh token does not match the stored hash', async () => {
      tokens.verify.mockResolvedValue({ sub: 'u1', fid: 'f1', typ: 'refresh' });
      prisma.user.findUnique.mockResolvedValue({
        ...sampleUser,
        refreshTokenHash: sha256('a-different-token'),
      });
      await expect(
        service.refresh({ refreshToken: validRefresh }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('logout', () => {
    it('clears the stored refresh hash', async () => {
      prisma.user.update.mockResolvedValue({ ...sampleUser });
      await service.logout('u1');
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'u1' },
        data: { refreshTokenHash: null },
      });
    });
  });
});
