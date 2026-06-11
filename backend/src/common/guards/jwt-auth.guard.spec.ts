import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { TokenService } from '../../auth/token.service';
import { JwtAuthGuard } from './jwt-auth.guard';

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

describe('JwtAuthGuard', () => {
  const tokens = { verify: jest.fn() } as unknown as TokenService;
  let guard: JwtAuthGuard;

  beforeEach(() => {
    jest.clearAllMocks();
    guard = new JwtAuthGuard(tokens);
  });

  it('allows a valid access token and attaches the user', async () => {
    (tokens.verify as jest.Mock).mockResolvedValue({
      sub: 'u1',
      fid: 'f1',
      role: 'PARENT',
      typ: 'access',
    });
    const { ctx, req } = context({ authorization: 'Bearer good' });
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(req.user).toEqual({ userId: 'u1', familyId: 'f1', role: 'PARENT' });
  });

  it('rejects a missing token', async () => {
    const { ctx } = context({});
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects a non-Bearer scheme', async () => {
    const { ctx } = context({ authorization: 'Basic abc' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects an unverifiable token', async () => {
    (tokens.verify as jest.Mock).mockRejectedValue(new Error('bad'));
    const { ctx } = context({ authorization: 'Bearer bad' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects a device token on a parent route', async () => {
    (tokens.verify as jest.Mock).mockResolvedValue({ sub: 'd1', typ: 'device' });
    const { ctx } = context({ authorization: 'Bearer device' });
    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
