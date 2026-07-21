# Product Decision: Why No Subscription in the MVP

- **Status:** Accepted
- **Date:** 2026-07-21

## Context
With ads ruled out ([why-no-ads.md](why-no-ads.md)), subscription is the natural revenue model. But
introducing a paywall too early — before the product has proven it delivers *understanding* — kills
adoption and taints the first-run experience.

## Decision
The **MVP and v1.0 ship with no subscription and no paywall.** All core value (logging, dashboard,
reports, rule-based insights, backup/export) is free. Monetization via **optional premium** features is
deferred to a later stage ([docs/15 Release Roadmap](../docs/15-release-roadmap.md)).

## Rationale
- **Earn trust first:** users must experience the core payoff (day-to-first-insight ≤ 7 days,
  [docs/01 §7](../docs/01-vision.md)) before we ask for money.
- **Adoption > early revenue:** a privacy-first app grows on trust and word of mouth; a day-one paywall
  throttles that.
- **Behavioral integrity:** no decision-fatigue or pressure at onboarding
  ([knowledge/psychology/decision-fatigue.md](../knowledge/psychology/decision-fatigue.md)).
- **Fairness:** the essential health journal — the thing that helps people understand their body —
  should not be locked behind a wall.

## Consequences
- **Cost:** no revenue during MVP/v1.0; premium must later add *genuinely* extra value (advanced AI,
  cloud sync, doctor/family features) without crippling the free core.
- **Benefit:** faster, cleaner adoption and a trust foundation to build premium on.

## Revisit if
The product has demonstrated value and a premium tier can add clearly-additive features **without**
degrading the free core — planned for the **Premium** stage in [docs/15](../docs/15-release-roadmap.md).

## Links
[why-no-ads.md](why-no-ads.md) · [docs/15 Release Roadmap](../docs/15-release-roadmap.md) · [docs/01 Vision](../docs/01-vision.md)
