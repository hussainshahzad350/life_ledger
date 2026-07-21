# Source: USDA FoodData Central

> Part of the [Research Registry](00-index.md). Tier **T1** (official food-composition dataset).

## What it is
**USDA FoodData Central (FDC)** is the U.S. Department of Agriculture's integrated food-composition
database (Foundation Foods, SR Legacy, Branded Foods, etc.), providing per-food nutrient values.

## Why LifeLedger trusts it
Authoritative, comprehensive, and (critically for an offline app) available in bulk with an open
data posture — a strong **candidate seed** for the bundled offline food database.

## How LifeLedger uses it
| Guidance / data | Where | Evidence |
|---|---|---|
| Per-food composition (calories, protein, carbs, fat, fiber, sugar) | Seed food catalog → [docs/17 Food Database](../docs/17-food-database.md), tables in [docs/04 §4.3](../docs/04-database-design.md) | **A** |
| **Atwater general factors** (4 kcal/g protein & carb, 9 kcal/g fat, 7 kcal/g alcohol) | [docs/06 §6](../docs/06-health-rules.md), [knowledge/fat.md](../knowledge/fat.md) | **A** |
| Micronutrient values (future) | [docs/17](../docs/17-food-database.md) `food_item_nutrient` | **A** |

## Licensing (must confirm before bundling)
- USDA FDC data is generally U.S. Government work / open, but **exact license, attribution, and the
  specific dataset subset must be confirmed** before bundling into the app. Tracked as a sourcing
  task in [docs/12 §6](../docs/12-implementation-plan.md). `[verify license + attribution]`

## References
- USDA FoodData Central (fdc.nal.usda.gov). `[verify dataset version/date at bundle time]`

## Notes / caveats
- FDC is U.S.-centric; South-Asian staples and restaurant/brand items need supplementary/localized
  data → [pakistan-nutrition-data.md](pakistan-nutrition-data.md).
- Branded Foods entries are contributor-provided — treat quality as variable; prefer Foundation/SR
  for staples.
