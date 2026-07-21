# Water

> [Knowledge Base](00-index.md) · Nutrition/Hydration. See also [hydration.md](hydration.md) for the *behavioral* side.

## Definition
Water is essential for nearly every bodily process — temperature regulation, circulation, digestion,
joint lubrication, and waste removal. It comes from beverages **and** food.

## Benefits
- Maintains blood volume, temperature control, and cognitive/physical performance. *(A)*
- Supports digestion and, with fiber, regularity. *(B)* → [fiber.md](fiber.md)
- Adequate hydration is linked to better perceived energy and concentration. *(B)*

## Deficiency
Even mild dehydration can cause fatigue, headache, reduced concentration, and thirst. Answers the
mission question *"am I drinking enough water?"*. *(A/B.)*

## Upper Limits
Excessive water in a short time can cause **hyponatremia** (dangerously low sodium) — rare but real.
LifeLedger clamps the water *goal* to a safe band `[MIN_WATER_ML 1500, MAX_WATER_ML 4000]`
([docs/06 §7](../docs/06-health-rules.md)). *(A.)*

## Sources
- Body-weight method **~30–35 ml/kg** (LifeLedger uses `WATER_ML_PER_KG = 33`) → [docs/06 §7](../docs/06-health-rules.md). **B**
- Total-water Adequate Intake anchors (~2.7 L women / ~3.7 L men incl. food) → [research/dietary-guidelines.md](../research/dietary-guidelines.md). **B** `[verify exact figures]`

## References
- IOM/NASEM DRI (Water & Electrolytes); EFSA hydration values differ — pin the chosen anchor. `[verify]`

## Common Misconceptions
- *"Everyone needs exactly 8 glasses a day."* A useful rule of thumb, not a universal requirement;
  needs vary with size, climate, and activity. *(B)*
- *"Coffee/tea don't count / are dehydrating."* Moderate caffeinated drinks still contribute to
  hydration. *(B)*
- *"Thirst means you're already dangerously dehydrated."* Thirst is a normal early cue. *(B)*

## Evidence Level
Core role & mild-dehydration effects: **A/B**. Exact daily targets: **B** (individual variation).

## How LifeLedger Uses This
- **Health rule:** water goal by body weight, clamped to band → [docs/06 §7](../docs/06-health-rules.md).
- **Decision engine:** *Water Evaluation* → [docs/18](../docs/18-health-decision-engine.md).
- **AI rules:** `STREAK_WATER_MISS`, `HYDRATION_TIMING` → [docs/07 §3](../docs/07-ai-rules.md).
- **Feature:** one-tap water logging → [docs/08 F4](../docs/08-feature-specs.md).

## Cross-links
[hydration.md](hydration.md) · [fiber.md](fiber.md) · [exercise.md](exercise.md)
