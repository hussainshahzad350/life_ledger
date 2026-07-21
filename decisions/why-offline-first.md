# Product Decision: Why Offline First

- **Status:** Accepted
- **Date:** 2026-07-21
- **Companion ADRs:** persistence [ADR-0005](../docs/adr/0001-record-architecture-decisions.md#adr-0005--persistence-sqlite-via-sqflite--forward-only-migrations); posture reflected in [docs/03 Architecture](../docs/03-architecture.md).

## Context
Health data is deeply personal, and users cannot always rely on connectivity. Many competing apps
require an account and a network round-trip just to log a meal — slow, privacy-eroding, and fragile.

## Decision
LifeLedger is **fully functional with the network permanently off.** No account required. All core
flows — logging, dashboard, reports, insights, backup — work on-device. Cloud sync is *optional* and
out of v1 scope ([docs/04 §10](../docs/04-database-design.md)).

## Rationale
- **Privacy** ([docs/01](../docs/01-vision.md)): data that never has to leave the device can't be
  intercepted, sold, or leaked by us. Aligns with [why-no-ads.md](why-no-ads.md).
- **Speed** ([docs/14 Performance](../docs/14-performance.md)): local SQLite reads make the < 10s log
  and ≤ 1.5s dashboard achievable; no network latency in the hot path.
- **Reliability:** the journal works on a plane, in a basement, on a dead SIM.
- **Ownership:** the user holds their data; export/backup make that concrete ([docs/08 F14](../docs/08-feature-specs.md)).

## Consequences
- **Cost:** we must design the schema sync-ready up front ([docs/04 §10](../docs/04-database-design.md)) so
  optional cloud sync is additive later; more careful migration/backup engineering.
- **Benefit:** a fundamentally more private, faster, more trustworthy product — and a real
  differentiator versus cloud-first competitors.

## Revisit if
A future feature genuinely requires server-side computation that cannot run on-device (e.g., some ML) —
and even then, only as an **opt-in**, clearly-labeled addition, never a requirement.

## Links
[docs/01 Vision](../docs/01-vision.md) · [docs/04 Database](../docs/04-database-design.md) · [docs/13 Security & Privacy](../docs/13-security-privacy.md) · [why-no-ads.md](why-no-ads.md)
