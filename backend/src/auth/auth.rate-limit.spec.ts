import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ThrottlerModule } from '@nestjs/throttler';
import request from 'supertest';
import { PairingController } from '../pairing/pairing.controller';
import { PairingService } from '../pairing/pairing.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';

describe('rate limit on credential endpoints', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const ref = await Test.createTestingModule({
      imports: [ThrottlerModule.forRoot([{ name: 'auth', ttl: 60_000, limit: 3 }])],
      controllers: [AuthController, PairingController],
      providers: [
        { provide: AuthService, useValue: { login: jest.fn().mockResolvedValue({}) } },
        { provide: PairingService, useValue: { claim: jest.fn().mockResolvedValue({}) } },
        { provide: TokenService, useValue: { verify: jest.fn() } },
      ],
    }).compile();
    app = ref.createNestApplication();
    await app.init();
  });

  afterEach(() => app.close());

  it.each([
    ['/auth/login', { email: 'a@b.co', password: 'guess' }],
    ['/pairings/claim', { token: 'AAAA-BBBB' }],
  ])('%s answers 429 once the per-minute limit is spent', async (path, body) => {
    const hit = () => request(app.getHttpServer()).post(path).send(body);
    for (let i = 0; i < 3; i++) {
      expect((await hit()).status).toBe(200);
    }
    expect((await hit()).status).toBe(429);
  });
});
