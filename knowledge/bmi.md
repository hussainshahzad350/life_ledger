# Body Mass Index (BMI)

> [Knowledge Base](00-index.md) · Health.

## Definition
BMI is `weight_kg / (height_m)²` — a simple ratio used to screen weight status at the **population**
level. It is a screening indicator, **not** a diagnosis or a measure of body composition.

## Benefits
- Quick, cheap, standardized screen for under/overweight trends. *(A)*
- Useful as one input among many for setting sensible goals. *(B)*

## "Deficiency" / What it misses
- BMI **cannot distinguish muscle from fat**: a muscular person may read "overweight." *(A)*
- Doesn't capture fat distribution or ethnicity-specific risk. *(A/B)*

## Upper Limits / Categories (WHO, adults)
| BMI | Category |
|---|---|
| < 18.5 | Underweight |
| 18.5–24.9 | Normal |
| 25.0–29.9 | Overweight |
| ≥ 30.0 | Obese |

→ [research/who.md](../research/who.md). **A**

## Sources
- WHO BMI classification → [research/who.md](../research/who.md). **A**
- Formula in [docs/06 §8](../docs/06-health-rules.md).

## References
- WHO BMI fact sheet. `[verify]`

## Common Misconceptions
- *"BMI tells me how healthy I am."* It's a screening ratio, not a health verdict. *(A)*
- *"Normal BMI = healthy; high BMI = unhealthy."* Composition, fitness, and other markers matter. *(A)*

## Evidence Level
Classification cut-offs: **A**. Individual interpretation: **A** that it's *limited*.

## How LifeLedger Uses This
- **Health rule:** BMI computed with a clear "screening tool, not diagnosis" caveat → [docs/06 §8](../docs/06-health-rules.md).
- **Decision engine:** *BMI Evaluation* (category + caveat) → [docs/18](../docs/18-health-decision-engine.md).
- **UI:** always shows the limitation note ([docs/05](../docs/05-uiux-system.md)).

## Cross-links
[weight_loss.md](weight_loss.md) · [exercise.md](exercise.md) · [protein.md](protein.md)
