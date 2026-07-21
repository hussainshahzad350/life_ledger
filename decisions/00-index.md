# LifeLedger Product Decisions — Index

> **Product "why", distinct from architecture "why".** This folder records *product* decisions —
> choices about what LifeLedger is and refuses to be. Technical/architecture decisions live in the
> append-only [ADR log](../docs/adr/0001-record-architecture-decisions.md).

Return to the [specification index](../docs/00-README-index.md).

---

## 1. Product Decisions vs. Architecture Decisions (ADRs)

| | Product Decision (`/decisions`) | Architecture Decision Record (`docs/adr`) |
|---|---|---|
| Answers | *Why does the product behave this way for users?* | *Why is the system built this way technically?* |
| Example | "Why no ads" | "Why BLoC" |
| Owner mindset | Product/UX/ethics | Engineering |
| Format | Context · Decision · Rationale · Consequences · Revisit-if | ADR template (Status/Context/Decision/Consequences/Alternatives) |

Both are append-only and cross-linked. A single theme can appear in both lenses (e.g., *offline-first*
is a product promise **and** an architecture posture).

## 2. Decision ↔ ADR Mapping

The user's mental model listed several "ADRs" that are really a mix of product and architecture
decisions. This table reconciles them **without renumbering** the existing ADRs (append-only integrity):

| Theme | Product Decision | Architecture ADR |
|---|---|---|
| Why BLoC | — | [ADR-0002](../docs/adr/0001-record-architecture-decisions.md#adr-0002--state-management-bloc--cubit) |
| Why SQLite | — | [ADR-0005](../docs/adr/0001-record-architecture-decisions.md#adr-0005--persistence-sqlite-via-sqflite--forward-only-migrations) |
| Why AI is Rule-Based First | [why-ai-is-not-a-doctor.md](why-ai-is-not-a-doctor.md) (ethics side) | [ADR-0007](../docs/adr/0001-record-architecture-decisions.md#adr-0007--ai-is-on-device-rule-based-and-deterministic-in-v1) (technical side) |
| Why Offline First | [why-offline-first.md](why-offline-first.md) | (posture reflected across ADR-0005, docs/03) |
| Why No Ads | [why-no-ads.md](why-no-ads.md) | — |
| Why No Subscription in MVP | [why-no-subscription-in-mvp.md](why-no-subscription-in-mvp.md) | — |
| Why Health Score Exists | [why-health-score-exists.md](why-health-score-exists.md) | — |

## 3. Contents

- [why-offline-first.md](why-offline-first.md)
- [why-no-ads.md](why-no-ads.md)
- [why-no-subscription-in-mvp.md](why-no-subscription-in-mvp.md)
- [why-ai-is-not-a-doctor.md](why-ai-is-not-a-doctor.md)
- [why-health-score-exists.md](why-health-score-exists.md)

## 4. Template

```
# Product Decision: <Title>
- Status: Accepted | Superseded by <link> | Revisiting
- Date: YYYY-MM-DD
- Context: the user/market/ethical force behind this.
- Decision: what we commit to.
- Rationale: why this serves the mission ([docs/01](../docs/01-vision.md)) and the user.
- Consequences: what it costs us and what it protects.
- Revisit if: the specific condition under which we'd reconsider.
- Links: related knowledge, ADRs, features.
```

New product decisions append here and, if they touch technical structure, get a companion ADR.
