# Product Decision: Why No Ads

- **Status:** Accepted
- **Date:** 2026-07-21

## Context
Advertising is the default monetization for consumer health apps. It also fundamentally conflicts with
a privacy-first health journal: ad networks depend on tracking, profiling, and data sharing.

## Decision
LifeLedger will contain **no advertisements and no third-party ad/analytics SDKs**, ever. There is no
tracking, no profiling, no silent telemetry ([docs/02 NFR-5/6](../docs/02-requirements.md)).

## Rationale
- **Privacy is the product** ([docs/01](../docs/01-vision.md)): ads require the exact data flows we
  promise to prevent. You cannot be privacy-first and ad-funded.
- **Trust:** users share intimate health data only if they believe it won't be monetized against them.
- **UX integrity:** ads corrupt a calm, focused health experience and add attention-hijacking pressure
  that contradicts our behavioral ethics ([knowledge/psychology/reward-system.md](../knowledge/psychology/reward-system.md)).
- **Attention is not the product.** We optimize for user understanding, not engagement/impressions.

## Consequences
- **Cost:** we forgo the easiest revenue model and must fund the app another way
  → [why-no-subscription-in-mvp.md](why-no-subscription-in-mvp.md) (premium later, not ads).
- **Benefit:** a defensible, trustworthy brand and a clean, fast app.

## Revisit if
Never for advertising. Monetization questions are answered by premium features
([docs/15 Release Roadmap](../docs/15-release-roadmap.md)), not ads.

## Links
[docs/01 Vision](../docs/01-vision.md) · [docs/13 Security & Privacy](../docs/13-security-privacy.md) · [why-offline-first.md](why-offline-first.md) · [why-no-subscription-in-mvp.md](why-no-subscription-in-mvp.md)
