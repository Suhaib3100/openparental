# Contributing to monii

Thanks for your interest! monii is a consent-first parental-control stack, and
contributions of every size are welcome — bug reports, OEM test results, docs,
and code.

## Ground rules

- **No covert surveillance.** PRs that add hidden recording, stealth modes,
  covert capture, or anything the child can't see will be declined. monii is
  bypass-evident by design — that constraint is the product.
- Be kind. See our [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

- 🐛 **Bug reports** — open an issue with steps to reproduce.
- 📱 **OEM survival reports** — run the child app overnight on your device
  (especially Xiaomi/MIUI, Samsung, OnePlus, Oppo/realme) and report whether the
  foreground service survived. This data directly shapes the onboarding flow.
- 💡 **Features** — check the roadmap in the README first; open an issue to
  discuss before building anything large.
- 📖 **Docs** — setup friction you hit is setup friction worth fixing.

## Development setup

Each component has its own README with full instructions:

| Component | Requirements | Dev loop |
|---|---|---|
| [`backend/`](backend) | Node 20+, Docker | `docker compose up -d && npm run start:dev` |
| [`android-managed/`](android-managed) | JDK 17, Android Studio | open in Studio, run on a device |
| [`app-parent/`](app-parent) | Flutter 3.22+ | `flutter run` |

## Before you open a PR

1. **Backend:** `npm run build && npm test` must pass (run
   `npm run prisma:generate` first).
2. **Child app:** `./gradlew assembleDebug` must compile.
3. **Parent app:** `flutter analyze` must be clean.

CI runs all three on every PR.

## Commit style

Short, imperative, scoped by component — matching the existing history:

```
backend: add unblock-request endpoint
managed: debounce accessibility tamper events
parent: show device battery on dashboard
```

## Questions?

Open a [discussion or issue](https://github.com/Suhaib3100/monii/issues) — happy
to help you get started.
