import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { TokenService } from '../../auth/token.service';
import { PrismaService } from '../../prisma/prisma.service';
import { DeviceAuthGuard } from './device-auth.guard';

function context(headers: Record<string, unknown>): {
  ctx: ExecutionContext;
  req: Record<string, unknown>;
} {
  const req: Record<string, unknown> = { headers };
  const ctx = {
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
  return { ctx, req };
}

describe('DeviceAuthGuard', () => {
  const tokens = { verify: jest.fn() } as unknown as TokenService;
  const findUnique = jest.fn();
  const prisma = { device: { findUnique } } as unknown as PrismaService;
  let guard: DeviceAuthGuard;

  beforeEach(() => {
    jest.clearAllMocks();
    findUnique.mockResolvedValue({ familyId: 'f1' });
    guard = new DeviceAuthGuard(tokens, prisma);
  });

  it('allows a valid device token and attaches the device', async () => {
    (tokens.verify as jest.Mock).mockResolvedValue({
      sub: 'd1',
      fid: 'f1',
      typ: 'device',
    });
    const { ctx, req } = context({ authorization: 'Bearer good' });
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(req.device).toEqual({ deviceId: 'd1', familyId: 'f1' });
  });

  it('rejects a token for a device the parent removed', async () => {
    (tokens.verify as jest.Mock).mockResolvedValue({
      sub: 'd1',
      fid: 'f1',
      typ: 'device',
    });
    findUnique.mockResolvedValue(null);
    const { ctx } = context({ authorization: 'Bearer old' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects an access token on a device route', async () => {
    (tokens.verify as jest.Mock).mockResolvedValue({ sub: 'u1', typ: 'access' });
    const { ctx } = context({ authorization: 'Bearer parent' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects a missing token', async () => {
    const { ctx } = context({});
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
