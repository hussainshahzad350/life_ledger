# Carbohydrates

> [Knowledge Base](00-index.md) · Nutrition.

## Definition
Carbohydrates are the body's primary energy source, found as sugars, starches, and fiber. They break
down to glucose, which fuels the brain and muscles. Fiber is a carbohydrate the body doesn't fully
digest ([fiber.md](fiber.md)).

## Benefits
- Efficient, readily-available **energy**, especially for the brain and higher-intensity activity. *(A)*
- Whole-food carbs deliver **fiber**, vitamins, and minerals. *(A)*
- Adequate carbs spare protein from being used for energy. *(B)*

## Deficiency
Very low carbohydrate intake can cause short-term fatigue, headaches, and reduced high-intensity
performance ("low-carb flu"); the body adapts by using fat/ketones. Not a clinical deficiency for most,
but relevant to how a user *feels* — a pattern the journal can surface. *(B/C.)*

## Upper Limits
No UL for total carbohydrate. The meaningful limit is on **free/added sugars**: WHO recommends **< 10%
of total energy** (conditional < 5%). LifeLedger treats added sugar as a **ceiling, not a goal**
(`ADDED_SUGAR_MAX_PCT = 0.10`, [docs/06 §6.1](../docs/06-health-rules.md)). *(A.)*

## Sources
- **AMDR carbs 45–65% of energy** → [research/dietary-guidelines.md](../research/dietary-guidelines.md). **A**
- **Free sugars < 10%** → [research/who.md](../research/who.md). **A**

## References
- IOM/NASEM DRI (AMDR). `[verify]`
- WHO *Sugars intake* guideline. `[verify]`

## Common Misconceptions
- *"Carbs make you fat."* Excess **total energy** drives fat gain, not carbs specifically. *(A)*
- *"All carbs are the same."* Whole grains/legumes/fruit differ greatly from refined sugar in fiber
  and satiety. *(A)*
- *"You must avoid carbs to lose weight."* Weight loss follows an energy deficit; carb level is a
  personal preference/adherence choice. *(A)* → [weight_loss.md](weight_loss.md)

## Evidence Level
Energy role & AMDR: **A**. Free-sugar limit: **A**. "Low-carb flu" specifics: **C**.

## How LifeLedger Uses This
- **Health rule:** carbs fill the post-protein energy remainder (`CARB_SHARE`) → [docs/06 §6](../docs/06-health-rules.md).
- **Feature:** carb + sugar tracking per food entry → [docs/08 F3](../docs/08-feature-specs.md).
- **AI/Help:** sugar-ceiling framing (supportive, not punitive).

## Cross-links
[fiber.md](fiber.md) · [fat.md](fat.md) · [protein.md](protein.md) · [weight_loss.md](weight_loss.md)
