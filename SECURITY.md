# Security Policy

monii handles family data — device locations, app usage, and remote-control
commands for minors' devices. Security reports are taken seriously.

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Report privately via
[GitHub Security Advisories](https://github.com/Suhaib3100/monii/security/advisories/new)
("Report a vulnerability" on the repo's Security tab).

You can expect an acknowledgment within a few days. Please include reproduction
steps and the affected component (`backend`, `android-managed`, `app-parent`).

## Scope

Especially interested in:

- Auth/token issues — parent JWT, refresh rotation, device-token scoping
- Cross-family data access (one parent reaching another family's devices)
- Pairing-code brute force or hijack
- Command-spine abuse (forging, replaying, or escalating device commands)
- Child-app hardening gaps that allow *silent* bypass (bypass is expected —
  monii is bypass-evident — but a bypass that produces **no tamper alert** is a
  vulnerability)

## Out of scope

- "The child can disable the app" — by design, as long as the parent is alerted
- Issues requiring a rooted device or Device Owner
- Denial of service via volume alone

## Supported versions

| Version | Supported |
|---|---|
| `main` | ✅ |
