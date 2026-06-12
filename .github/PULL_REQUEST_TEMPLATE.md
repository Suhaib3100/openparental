## What

<!-- What does this PR change? One or two sentences. -->

## Why

<!-- What problem does it solve? Link the issue if there is one. -->

Closes #

## Component

- [ ] `backend`
- [ ] `android-managed` (child app)
- [ ] `app-parent` (parent app)
- [ ] CI / docs

## Checks

- [ ] Backend: `npm run build && npm test` pass (if backend touched)
- [ ] Child app: `./gradlew assembleDebug` compiles (if touched)
- [ ] Parent app: `flutter analyze` clean (if touched)
- [ ] No covert-surveillance functionality — everything this adds is visible to the child
