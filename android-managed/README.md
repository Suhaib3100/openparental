# android-managed — Spike #1: FGS survival

A minimal app that does **nothing but stay alive** as a foreground service, so we
can measure whether an always-on anchor survives Android 14/15 runtime caps and
OEM battery-killers **before** building the real managed app on top of it.

This is not throwaway: `SupervisorService`, `BootReceiver`, `WatchdogWorker`, and
`SurvivalLog` are the seed of the real managed core (Phase 3).

## What it measures

- Whether `specialUse` FGS stays foreground for hours/overnight.
- How often the OEM kills it (watchdog + boot restart counts).
- Whether boot restart, swipe-away (`onTaskRemoved`), and the 15-min WorkManager
  watchdog bring it back.

## Run it

Requires **JDK 17** + Android Studio (or a local Gradle 8.9).

```bash
cd android-managed
# Android Studio: just open this folder and Run on a device.
# CLI (after generating the wrapper once):
gradle wrapper --gradle-version 8.9      # only needed once; or let Studio do it
./gradlew assembleDebug
./gradlew installDebug                    # device connected via adb
```

The wrapper jar is intentionally not committed; Android Studio or `gradle wrapper`
generates it.

## The test protocol

1. Install, open the app (it auto-starts the service).
2. Tap **Allow unrestricted battery** and **Open autostart settings** — enable both.
   (This is exactly the per-OEM onboarding the real product will need.)
3. Reboot the phone → confirm `Boot restarts` increments and the service comes back.
4. Swipe the app from recents → watch `Service starts` / watchdog behavior.
5. Leave it overnight, screen off, unplugged. Reopen in the morning.

## Reading the result

- `Watchdog restarts: 0`, `Boot restarts: matches reboots`, last heartbeat recent
  → `specialUse` survives on this device. Good foundation.
- Many watchdog restarts or stale heartbeats overnight → this OEM kills the anchor;
  the onboarding *must* force the battery/autostart steps, and we may need to test
  `dataSync` vs `specialUse` or a secondary keep-alive. That is the decision this
  spike exists to make.

Test on at least: a stock Pixel, a Xiaomi/Redmi (MIUI), and a Samsung.
