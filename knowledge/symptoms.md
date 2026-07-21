# Symptoms (Tracking & Correlation)

> [Knowledge Base](00-index.md) · Health. This file governs how LifeLedger treats symptom data —
> with strong **honesty and safety** guardrails.

## Definition
A symptom is a subjective experience the user reports (e.g., bloating, headache, fatigue, low energy).
In LifeLedger, symptoms are **user-logged signals** used to find *personal* associations with foods,
sleep, and habits — never to diagnose.

## Benefits (of tracking)
- Reveals **personal** patterns a user can't hold in memory across weeks (Persona B's core need,
  [docs/01](../docs/01-vision.md)). *(B for the method; D for any specific personal finding.)*
- Produces an exportable record to discuss with a real clinician. *(B)*

## "Deficiency" / Risks of doing it wrong
- **Correlation ≠ causation.** Many factors affect symptoms; a co-occurrence is a hint, not a cause.
- **Data dredging** across many food↔symptom pairs inflates false positives — LifeLedger tests only a
  small, plausible set ([docs/07 §5](../docs/07-ai-rules.md)).

## Upper Limits / Safety
- The app **never names a disease** or suggests a diagnosis from symptoms
  ([why-ai-is-not-a-doctor.md](../decisions/why-ai-is-not-a-doctor.md)).
- Persistent/severe symptoms → the only action is a neutral suggestion to consider a clinician
  (conservative, roadmap red-flag routing, [docs/07 §6](../docs/07-ai-rules.md)).

## Sources
- Correlation-honesty rationale → [docs/07 §5/§6](../docs/07-ai-rules.md), [research/research-papers.md](../research/research-papers.md) `[verify]`.

## References
- Nutrition-epidemiology caveats on association vs causation. `[verify]`

## Common Misconceptions
- *"The app found the food that causes my symptom."* It found an **association** in *your* data, at a
  stated (usually low) confidence — not a proven cause. *(design principle)*
- *"No insight means nothing is wrong."* Silence often means insufficient data, by design (the app
  won't guess). *(design principle)*

## Evidence Level
Method (personal correlation): **B**. Any specific user finding: **D** (personal pattern, hedged).

## How LifeLedger Uses This
- **Feature:** symptom logging (type + severity 1–5) → [docs/08 F8](../docs/08-feature-specs.md); tables
  `symptom_entry`/`symptom_type` ([docs/04 §4.5/4.6](../docs/04-database-design.md)).
- **AI rules:** `CORR_FOOD_SYMPTOM` (capped low/medium, hedged) → [docs/07 §3/§5](../docs/07-ai-rules.md).
- **Decision engine:** feeds pattern reports, not the health score.

## Cross-links
[digestion.md](digestion.md) · [gut_health.md](gut_health.md) · [sleep.md](sleep.md)
