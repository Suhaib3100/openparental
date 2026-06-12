# monii

Android parental enforcement, built **bypass-evident, not bypass-proof**. Overt,
consent-based, no Device Owner, no covert surveillance.

## Monorepo layout

```
/backend           Node + TypeScript (NestJS) + Postgres + Redis + FCM   ✅ built + tested
/android-managed   Kotlin managed (child) app — sideloaded APK only       ✅ built (CI-verified)
/app-parent        Flutter controller (parent) app — Play AAB             ✅ built (CI-verified)
```

## Milestones

- **v1 = GREEN** (enforcement, limits, tamper-evidence, safety, location) — **built**
- **v1.5** = WebRTC consented screen-view + AMBER (text archive + on-device photo)
- **v1.1** = Live Painting overlay

## Hard exclusions (legal)

No covert audio/camera, no ambient recording, no covert screen capture, no
server-side storage of minors' photos (CSAM strict liability), no Device Owner.

## What works end-to-end (v1 GREEN)

Parent registers → creates a pairing code → child app claims it (gets a device
token) → parent sees the device, sends **Lock** / **Ping**, edits a **blocked-apps
policy** that pushes to the device → child enforces it (Accessibility bounces
blocked/over-limit/scheduled apps) → child heartbeats + reports **tamper** (a
disabled layer) and **new-app/location/usage** → parent sees **alerts**. "Went
dark" is reconciled server-side from Postgres (no false alarm on a Redis restart).

## Run it

```bash
# 1. Backend
cd backend
cp .env.example .env && docker compose up -d        # Postgres + Redis
npm install && npm run prisma:generate && npm run prisma:migrate
npm run start:dev                                   # http://localhost:3000/health

# 2. Managed (child) app — Android Studio, run on a device, then in-app:
#    set Backend URL (http://10.0.2.2:3000 from the emulator) + the pairing code.

# 3. Parent app
cd app-parent && flutter pub get && flutter run     # set Backend URL on the login screen
```

CI (`.github/workflows/ci.yml`) builds + tests the backend, `assembleDebug`s the
managed app, and `flutter analyze`s the parent app on every push.

## Status

| Tier | State |
|---|---|
| Backend (auth, pairing, command spine, policy, events, tamper, heartbeat, locations, alerts) | ✅ 68 unit tests, builds clean |
| Managed app (pair, heartbeat, command/lock, enforcement, tamper, visibility) | ✅ built; CI compiles it |
| Parent app (login, pairing, dashboard, lock, policy editor, alerts) | ✅ built; CI analyzes it |

### Deferred (external dependency or v1.5)

- **FCM push** — needs your Firebase project + `google-services.json`. The device
  polls every 60s today; FCM bolts on for instant wake.
- **VPN content filter** — build on a maintained DNS-filter base (not a hand-rolled
  packet loop), per the plan.
- **Phase 0b survival spike** — run `/android-managed` overnight on a real Xiaomi to
  confirm the `specialUse` FGS survives before relying on it.
- **v1.5** — WebRTC consented screen-view, AMBER (text archive + on-device photo/NCMEC).
- **Onboarding UI** — guided per-OEM battery + special-access grant flow.

## Toolchain

- Backend: Node 20+, Docker (Postgres 16 + Redis 7)
- Android: JDK 17, AGP 8.6.1, Kotlin 2.0.20, Gradle 8.9, SDK 35
- Parent app: Flutter 3.22+
