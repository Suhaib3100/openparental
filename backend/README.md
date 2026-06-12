# openparental-backend

Node + TypeScript (NestJS) backend: auth, pairing, command spine, policy, events,
tamper, heartbeat, alerts. Postgres (Prisma) + Redis + FCM.

## Run locally

```bash
cp .env.example .env
docker compose up -d            # Postgres + Redis
npm install
npm run prisma:generate         # generate the Prisma client (required before tests)
npm run prisma:migrate          # create the schema (first run)
npm run start:dev               # http://localhost:3000/health
```

## Test

```bash
npm run prisma:generate         # tests import the generated client
npm test                        # unit tests
npm run test:cov                # with coverage
npm run test:e2e                # end-to-end (needs Postgres + Redis up)
```

## Layout

```
src/
  config/        env configuration
  prisma/        PrismaService (global)
  redis/         RedisService (global) — presence / heartbeat keys
  common/        guards (JwtAuthGuard, DeviceAuthGuard), decorators, hash utils, types
  auth/          register / login / refresh / logout + TokenService     [done]
  pairing/       QR/code issue + device claim → device token            [next]
  devices/       device registry, status, info                          [next]
  policies/      rules CRUD, versioned                                  [next]
  commands/      command spine (enqueue → FCM → ack/result)             [next]
  events/        batched event ingestion                                [next]
  heartbeats/    presence + "went dark" reconciler                      [next]
  tamper/        tamper events + alert fan-out                          [next]
  alerts/        alert feed + FCM to parent                             [next]
  locations/     location ingest + query                               [next]
  fcm/           push abstraction (firebase-admin)                      [next]
  realtime/      WebSocket gateway (presence, screen-view signaling)    [next]
```

## Token model

- **access** (short TTL) — parent app, `Authorization: Bearer`. `JwtAuthGuard`.
- **refresh** (long TTL, rotated, sha256-hashed in DB) — parent app.
- **device** (very long TTL) — managed app, minted at pairing claim. `DeviceAuthGuard`.
