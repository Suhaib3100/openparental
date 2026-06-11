# monii

Android parental enforcement, built **bypass-evident, not bypass-proof**. Overt,
consent-based, no Device Owner, no covert surveillance.

See the engineering plan:
`~/.gstack/projects/unknown/suhaib-Suhaib3100-office-hours-app-eng-plan-20260612-011759.md`

## Monorepo layout

```
/android-managed   Kotlin managed (child) app — sideloaded APK only, never Play
/app-parent        Flutter controller (parent) app — Google Play (AAB) + App Store   [TBD]
/backend           Node + TypeScript (NestJS) — Auth, Pairing, Command, Heartbeat   [TBD]
/shared            Cross-tier contracts (policy/command JSON schema + types)         [TBD]
```

## Milestones (decided)

- **v1 = GREEN** (enforcement, limits, tamper-evidence, safety, location) — ship ~3mo
- **v1.5** = WebRTC consented screen-view + AMBER (text archive + on-device photo)
- **v1.1** = Live Painting overlay

Nothing is cut; this only sets ship order.

## Hard exclusions (legal)

No covert audio/camera, no ambient recording, no covert screen capture, no
server-side storage of minors' photos (CSAM strict liability), no Device Owner.

## Where we are

**Phase 0b — feasibility spikes** (retire the two unproven foundations first):

1. **Spike #1 — FGS survival** (`/android-managed`, this commit). A minimal app that
   does nothing but stay alive as a foreground service across reboots and OEM
   battery-kill, logging exactly when it dies and restarts. Run it overnight on a real
   Xiaomi/Oppo. Decides which FGS type survives Android 14/15 runtime caps.
2. **Spike #2 — MediaProjection → WebRTC** (TBD). Prove the screen-capture→encode→
   WebRTC pipeline on a real mid-range device + VpnService coexistence.

See `android-managed/README.md` to run spike #1.

## Toolchain

- Android: JDK 17, Android Studio (or `gradle wrapper` + Gradle 8.9), AGP 8.6.1, Kotlin 2.0.20
- Backend (TBD): Node 20+, pnpm
- Parent app (TBD): Flutter 3.x
