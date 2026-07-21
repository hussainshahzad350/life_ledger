# Source: Pakistan / South-Asian Nutrition Data

> Part of the [Research Registry](00-index.md). Tier **T4** (localized dataset — **to be sourced**).

## Why this matters
LifeLedger's mission ("understand your body") fails if a user in Pakistan can't quickly log *roti,
daal, biryani, nihari, chapati, lassi*. A U.S.-centric food DB ([usda.md](usda.md)) is not enough.
Localized food composition and, crucially, **aliases** (local names/spellings) are a first-class
requirement — see [docs/17 Food Database](../docs/17-food-database.md).

## What we need
| Need | Detail |
|---|---|
| Composition for South-Asian staples | Per-serving calories + macros for common Pakistani/Indian foods and dishes. |
| Realistic serving sizes | Cultural portions (1 roti, 1 cup daal, 1 plate biryani) → [docs/17 Serving Sizes](../docs/17-food-database.md). |
| Aliases / transliterations | e.g., roti/chapati/phulka; daal/dal; curd/dahi/yogurt → alias table in [docs/17](../docs/17-food-database.md). |
| Restaurant & brand items | Common local restaurant dishes and packaged brands (later phase). |

## Candidate sources (to evaluate — do not assume figures)
- Regional/national **food composition tables** for Pakistan and/or India `[verify existence, license]`.
- FAO/INFOODS regional tables `[verify]`.
- Peer-reviewed composition studies for specific dishes `[verify per-item]`.
- Community/crowd data — **only** with strong validation (quality varies).

## Status
**Unsourced.** No figures are asserted here. Until a licensed, credible dataset is confirmed:
- The food DB ships with USDA-derived staples + a small, clearly-marked set of local items whose
  values are pinned to a cited source.
- Users can always create custom foods ([docs/08 F3](../docs/08-feature-specs.md)) as the offline fallback.

## Open tasks
1. Identify a license-compatible South-Asian composition dataset. `[verify]`
2. Confirm serving-size conventions with the cited source. `[verify]`
3. Build the alias list (English + Urdu/Hindi transliterations) — localization surface, English is the
   canonical key ([docs/17](../docs/17-food-database.md)).
