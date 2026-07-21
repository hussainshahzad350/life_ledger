# Source: Dietary Guidelines for Americans (DGA) & IOM/NASEM DRIs

> Part of the [Research Registry](00-index.md). Tier **T1**.

## What it is
- **Dietary Guidelines for Americans (DGA)** — jointly issued by USDA and HHS, updated ~every 5 years.
- **Dietary Reference Intakes (DRIs)** — reference values (RDA, AI, UL, AMDR) from the Institute of
  Medicine / National Academies (now **NASEM**).

## Why LifeLedger trusts it
These are the canonical reference values for macronutrient ranges and adequate intakes used across
nutrition software and labeling.

## How LifeLedger uses it
| Guidance | Value used | Where | Evidence |
|---|---|---|---|
| **AMDR** (Acceptable Macronutrient Distribution Ranges) | Carbs 45–65%, Fat 20–35%, Protein 10–35% of energy | [docs/06 §6](../docs/06-health-rules.md), [knowledge/carbohydrates.md](../knowledge/carbohydrates.md), [knowledge/fat.md](../knowledge/fat.md) | **A** |
| **Protein RDA** | 0.8 g/kg/day (adults) | [docs/06 §5](../docs/06-health-rules.md), [knowledge/protein.md](../knowledge/protein.md) | **A** |
| **Fiber Adequate Intake** | ~14 g per 1,000 kcal | [docs/06 §6.1](../docs/06-health-rules.md), [knowledge/fiber.md](../knowledge/fiber.md) | **A/B** |
| **Total water AI** | ~2.7 L (women) / ~3.7 L (men) total water incl. food; ~2.0/2.5 L beverages `[verify exact figures]` | [knowledge/water.md](../knowledge/water.md), [docs/06 §7](../docs/06-health-rules.md) | **B** |

## References
- Dietary Guidelines for Americans (current edition). `[verify edition/year]`
- IOM/NASEM, *Dietary Reference Intakes* (Energy, Macronutrients, Water & Electrolytes volumes). `[verify]`

## Notes / caveats
- AMDR and RDA are population references; LifeLedger lets users override goals ([docs/08 F2](../docs/08-feature-specs.md)).
- Exact water AI figures vary by source (IOM vs EFSA); pin the chosen figure and note the origin.
