# Phase 17 — Food Database

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [04](04-database-design.md) (schema), [02](02-requirements.md). Related sources: [research/usda.md](../research/usda.md), [research/pakistan-nutrition-data.md](../research/pakistan-nutrition-data.md).

The food catalog is the backbone of fast, accurate logging. This document specifies its structure,
localization, sourcing, and the "less than 10 seconds" search experience — extending the base schema
in [04 §4.3](04-database-design.md).

---

## 1. Goals
- **Offline, comprehensive enough** to log common meals without the internet ([why-offline-first.md](../decisions/why-offline-first.md)).
- **Localized:** Pakistani/Indian staples and restaurant items are first-class, not afterthoughts.
- **Fast to search** (recents/favorites/aliases) to serve the < 10 s log ([16](16-behavioral-design.md)).
- **Honest data provenance** — every seed value traces to a source ([research/](../research/00-index.md)).

---

## 2. Catalog Components

### 2.1 Foods (`food_item`)
The core catalog row ([04 §4.3](04-database-design.md)): name, brand, serving size/unit, and per-serving
macros (calories, protein, carbs, fat, fiber, sugar). Flags: `is_custom`, `is_favorite`, `source_ref`.

### 2.2 Nutrients (macros — v1)
Per-serving: **calories, protein, carbs, fat, fiber, sugar** ([02 FR-11](02-requirements.md)). These feed
the health engine ([06](06-health-rules.md)) and dashboard.

### 2.3 Micronutrients (future — `food_item_nutrient`)
A key/value table (`nutrient_code`, `amount`, `unit`) keeps `food_item` stable while adding vitamins/
minerals later ([04 §4.9](04-database-design.md)). Codes are documented (e.g., `sodium_mg`, `vit_c_mg`).
Sourced from [research/nih.md](../research/nih.md)/[usda.md](../research/usda.md). Out of v1 scope.

### 2.4 Units
Canonical metric storage with display conversion ([04 §5](04-database-design.md)):
| Kind | Serving unit examples |
|---|---|
| Mass | `g` |
| Volume | `ml` |
| Count | `piece`, `slice`, `cup`, `tbsp`, `roti`, `plate` |
Count/cultural units map to a gram/ml equivalent per food where known (`serving_size` + `serving_unit`).

### 2.5 Serving Sizes
- Every food has a **realistic default serving** (1 egg, 1 cup daal, 1 roti) so quantity is a stepper,
  not a typing task ([decision-fatigue](../knowledge/psychology/decision-fatigue.md)).
- Cultural portions matter: "1 roti", "1 plate biryani" must exist as natural servings
  ([research/pakistan-nutrition-data.md](../research/pakistan-nutrition-data.md)).

### 2.6 Aliases
A food maps to many names/spellings/languages. An **alias table** (`food_alias`: `food_item_id`,
`alias`, `locale`) powers search:
- roti / chapati / phulka; daal / dal / lentils; curd / dahi / yogurt.
- English is the **canonical key**; aliases (incl. Urdu/Hindi transliterations) are the localized
  search surface ([02 NFR-24](02-requirements.md)).
- Enables the NL parser ([07 §7](07-ai-rules.md)) to match local terms.

### 2.7 Pakistani Foods `[verify data source]`
Localized staples and dishes with cited composition. Ships a small, source-pinned initial set; expands
as a licensed dataset is confirmed ([research/pakistan-nutrition-data.md](../research/pakistan-nutrition-data.md)).
No composition figures are asserted until sourced.

### 2.8 Indian Foods `[verify data source]`
Overlapping South-Asian cuisine; same sourcing discipline and alias strategy as §2.7.

### 2.9 Restaurant Foods (later phase)
Common local restaurant dishes as catalog items (estimated servings, clearly flagged as estimates).
Provenance and estimation method documented per item; users can always override.

### 2.10 Recipes (`recipe` + `recipe_ingredient`) — future
A recipe is a composite of `food_item`s with quantities; its nutrition is computed from ingredients and
a serving count. Lets users log "my chicken curry" once and reuse it. Schema sketched now, built later.

### 2.11 Brands
`brand` on `food_item` (and future normalized `brand` table). Branded packaged items (from
[USDA Branded Foods](../research/usda.md) or user-created) with barcode support arriving in v1.1
([15](15-release-roadmap.md)).

---

## 3. Data Model Additions (extends [04](04-database-design.md))
New/foreshadowed tables (created only when their feature ships; audit/sync columns per [04 §2.1](04-database-design.md)):
```
food_alias(id, food_item_id FK, alias, locale)                     # v1 (search)
food_item_nutrient(id, food_item_id FK, nutrient_code, amount, unit)  # future micros
recipe(id, name, servings, ...) / recipe_ingredient(recipe_id, food_item_id, quantity)  # future
brand(id, name)                                                    # future normalization
```
Index `food_alias(alias)` and keep `idx_food_item_name` ([04 §6](04-database-design.md)) for fast search.

---

## 4. Search Experience (the < 10 s enabler)
Priority order in Quick Add ([05 §5.2](05-uiux-system.md)):
1. **Recents** (most logged, most recent) — usually a single tap.
2. **Favorites** (`is_favorite`).
3. **Alias/prefix search** across `food_item.name` + `food_alias.alias` (locale-aware).
4. **NL parse** ([07 §7](07-ai-rules.md)) as an accelerator, always confirm-first.
5. **Create custom food** as the offline fallback — always available.

---

## 5. Sourcing & Licensing (must resolve before bundling)
- Seed staples from **USDA FoodData Central** — confirm license/attribution ([research/usda.md](../research/usda.md)). `[verify]`
- Localized data — confirm a credible, license-compatible South-Asian source ([research/pakistan-nutrition-data.md](../research/pakistan-nutrition-data.md)). `[verify]`
- Every seed row carries `source_ref`; user-created foods are marked `is_custom` and never claim a source.
- Tracked as a release-blocking task in [12 §6](12-implementation-plan.md).

---

## 6. Quality & Integrity
- Nutrient values non-negative (DB `CHECK`, [04 §11](04-database-design.md)); serving size > 0.
- Prefer authoritative Foundation/SR data over contributor Branded data for staples ([research/usda.md](../research/usda.md)).
- Restaurant/estimated items are visibly flagged as estimates.
- Editing a food follows the copy-on-write/versioning path to protect historical accuracy
  ([04 §9 / ADR-0006](04-database-design.md)).

---

## 7. Future Evolution
Barcode (v1.1) → recipes → micronutrients → restaurant DB → image recognition seeding new items
([07 §8](07-ai-rules.md)) — each additive on this schema.

---

*Next: [Phase 18 — Health Decision Engine](18-health-decision-engine.md).*
