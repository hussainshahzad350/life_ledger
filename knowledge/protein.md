# Protein

> [Knowledge Base](00-index.md) · Nutrition. Follows the [standard template](00-index.md#2-the-knowledge-file-template).

## Definition
Protein is one of the three macronutrients. It is built from amino acids and is used to build and
repair tissue (muscle, skin, enzymes, hormones). Nine amino acids are **essential** — the body
cannot make them, so they must come from food.

## Benefits
- Builds and preserves **muscle** (especially important during weight loss and with age). *(A)*
- High **satiety** — protein is the most filling macronutrient, which helps with appetite and answers
  the mission question *"why am I always hungry?"*. *(B)*
- Supports immune function, enzymes, and hormones. *(A)*
- Modest **thermic effect** (more energy used to digest it than carbs/fat). *(B)*

## Deficiency
Inadequate protein can contribute to muscle loss, poor recovery, weakened immunity, and (in severe
cases) edema. In everyday app use, the practical signal is chronically low protein-goal adherence —
surfaced gently, never as a diagnosis. *(A, but individual signs are not diagnostic — D at the person level.)*

## Upper Limits
No specific tolerable upper intake level (UL) is set for protein for healthy adults; very high intakes
are generally tolerated but offer diminishing returns. LifeLedger caps its *goal* at
`PROTEIN_HARD_CAP = 2.2 g/kg` ([docs/06 §5](../docs/06-health-rules.md)) as a sensible product ceiling.
People with kidney disease should follow clinical advice — the app defers to clinicians and never
prescribes. *(A / clinical caveat.)*

## Sources
- Protein **RDA 0.8 g/kg/day** → [research/dietary-guidelines.md](../research/dietary-guidelines.md) (IOM/NASEM DRI). **A**
- Active/athlete ranges **1.2–2.0 g/kg** → professional position stands, [research/research-papers.md](../research/research-papers.md). **B** `[verify exact stand]`
- AMDR protein **10–35% of energy** → [research/dietary-guidelines.md](../research/dietary-guidelines.md). **A**

## References
- IOM/NASEM *Dietary Reference Intakes* (protein RDA, AMDR). `[verify edition]`
- Sports-nutrition society position stand on protein for active individuals. `[verify]`

## Common Misconceptions
- *"More protein always means more muscle."* Beyond a sufficient intake, extra protein has
  diminishing returns; total training + calories matter. *(B)*
- *"High protein damages healthy kidneys."* Not supported for healthy individuals; a clinical concern
  only in existing kidney disease. *(B)*
- *"You can only absorb 30 g per meal."* Absorption isn't a hard per-meal wall; distribution helps
  muscle synthesis but total daily intake dominates. *(C)*

## Evidence Level
Core role and RDA: **A**. Active-range targets and satiety benefit: **B**. Timing/distribution nuances: **C**.

## How LifeLedger Uses This
- **Health rule:** protein goal `weight_kg × PROTEIN_FACTOR` → [docs/06 §5](../docs/06-health-rules.md).
- **Decision engine:** *Protein Evaluation* → [docs/18](../docs/18-health-decision-engine.md).
- **AI rules:** `TREND_PROTEIN_UP`, `GOAL_PROTEIN_GAP` → [docs/07 §3](../docs/07-ai-rules.md).
- **Feature:** protein target + tracking → [docs/08 F2/F3](../docs/08-feature-specs.md); dashboard metric.

## Cross-links
[carbohydrates.md](carbohydrates.md) · [fat.md](fat.md) · [weight_loss.md](weight_loss.md) · [exercise.md](exercise.md)
