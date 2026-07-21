# Weight Management

> [Knowledge Base](00-index.md) · Health. Framed as *understanding*, not a "quick fix"
> ([docs/01 non-goals](../docs/01-vision.md)).

## Definition
Weight change is driven primarily by **energy balance**: consistently consuming less energy than you
expend leads to loss; more leads to gain. Body weight fluctuates daily with water, food volume, and
glycogen — so **trend matters more than any single reading**.

## Benefits (of a healthy approach)
- Gradual loss (with adequate protein + activity) preserves muscle and is more sustainable. *(A/B)*
  → [protein.md](protein.md), [exercise.md](exercise.md)
- Trend-based tracking reduces anxiety from normal daily noise. *(B)*

## "Deficiency" / Pitfalls
- **Over-restriction** harms adherence, muscle, and metabolism perception; hence LifeLedger's
  `MIN_CALORIE_FLOOR = 1200 kcal/day` safety floor ([docs/06 §4.1](../docs/06-health-rules.md)). *(B)*
- Chasing the scale daily instead of the trend causes discouragement. *(B)* → [psychology/motivation.md](psychology/motivation.md)

## Upper Limits / Safety
- Very aggressive deficits are discouraged; the app never promises a rate and caps goals sensibly.
- Rapid unexplained weight change is a reason to consider a clinician — the app suggests, never
  diagnoses ([why-ai-is-not-a-doctor.md](../decisions/why-ai-is-not-a-doctor.md)). *(clinical caveat.)*

## Sources
- BMR **Mifflin–St Jeor (1990)**; TDEE via PAL → [research/research-papers.md](../research/research-papers.md). **A/B**
- **~7,700 kcal ≈ 1 kg** approximation (Wishnofsky), **explicitly a simplification** → [docs/06 §4.1](../docs/06-health-rules.md). **C**

## References
- Mifflin–St Jeor, Am J Clin Nutr 1990. Harris–Benedict activity factors. Wishnofsky 1958. `[verify]`

## Common Misconceptions
- *"A calorie deficit guarantees exactly X kg/week."* Real change is non-linear and individual; the
  7,700 kcal/kg figure is an estimate, not a promise. *(C)*
- *"Weight went up overnight = fat gain."* Usually water/food/glycogen; watch the trend. *(A)*
- *"Losing weight fast is best."* Gradual, muscle-sparing loss is more sustainable. *(B)*

## Evidence Level
Energy-balance principle: **A**. Rate estimates: **C**. Trend-over-noise: **B**.

## How LifeLedger Uses This
- **Health rule:** BMR→TDEE→calorie goal with objective adjustment + safety floor → [docs/06 §2–4](../docs/06-health-rules.md).
- **Decision engine:** *Weight Evaluation* + *Trend Evaluation* (moving average) → [docs/18](../docs/18-health-decision-engine.md).
- **AI rule:** `TREND_WEIGHT` → [docs/07 §3](../docs/07-ai-rules.md).
- **Feature:** weight logging + trend chart → [docs/08 F5](../docs/08-feature-specs.md).

## Cross-links
[protein.md](protein.md) · [carbohydrates.md](carbohydrates.md) · [fat.md](fat.md) · [bmi.md](bmi.md) · [exercise.md](exercise.md)
