import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { TokenService } from './token.service';

const config = (secret = 'test-secret'): ConfigService =>
  ({
    get: (k: string) => (k === 'jwt.secret' ? secret : 900),
  }) as unknown as ConfigService;

describe('TokenService', () => {
  let tokens: TokenService;

  beforeEach(() => {
    tokens = new TokenService(new JwtService({}), config());
  });

  it('signs and verifies an access token, preserving claims', async () => {
    const token = await tokens.signAccess('u1', 'f1', 'PARENT');
    const payload = (await tokens.verify(token)) as unknown as Record<string, unknown>;
    expect(payload.sub).toBe('u1');
    expect(payload.fid).toBe('f1');
    expect(payload.role).toBe('PARENT');
    expect(payload.typ).toBe('access');
  });

  it('tags refresh and device tokens with the right type', async () => {
    const refresh = (await tokens.verify(
      await tokens.signRefresh('u1', 'f1'),
    )) as unknown as Record<string, unknown>;
    const device = (await tokens.verify(
      await tokens.signDevice('d1', 'f1'),
    )) as unknown as Record<string, unknown>;
    expect(refresh.typ).toBe('refresh');
    expect(device.typ).toBe('device');
    expect(device.sub).toBe('d1');
  });

  it('rejects a token signed with a different secret', async () => {
    const other = new TokenService(new JwtService({}), config('other-secret'));
    const token = await other.signAccess('u', 'f', 'PARENT');
    await expect(tokens.verify(token)).rejects.toBeDefined();
  });
});
