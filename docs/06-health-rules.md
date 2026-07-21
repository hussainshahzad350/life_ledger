# Phase 6 — Health Rules (Rule-Based Health Engine)

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [02](02-requirements.md), [04](04-database-design.md). Feeds: [07](07-ai-rules.md), [08](08-feature-specs.md).

The health engine turns profile + logs into targets and indicators. It is **deterministic and
rule-based** — no black boxes. Every formula below is stated explicitly, cited to public health
guidance, and every assumption is flagged. **No magic numbers.**

> ⚠️ **Not medical advice.** These formulas are population-level estimates for a *journaling* app.
> They are informational, adjustable by the user, and never a diagnosis or a prescription. This
> disclaimer is surfaced in-app ([05](05-uiux-system.md) §5.5).

**Engineering rule:** every constant here maps to a **named** domain constant (no literals in
code). The engine lives in the pure **domain** layer ([03](03-architecture.md)) and is fully
unit-tested ([11](11-testing-strategy.md)) against the worked examples in this document.

---

## 1. Inputs

| Input | Source | Notes |
|---|---|---|
| Sex | `user_profile.sex` | affects BMR; `unspecified` → see §2.3 |
| Age | derived from `birth_date` | years, floored |
| Height | `user_profile.height_cm` | cm |
| Weight | latest `weight_entry.weight_kg` | kg; falls back to a user-entered current weight |
| Activity level | `user_profile.activity_level` | maps to a PAL multiplier (§3) |
| Objective | active `goal.objective` | maintain / lose / gain |

If a required input is missing, the engine returns a typed `ValidationFailure` and the UI prompts
for it — it never guesses silently.

---

## 2. Basal Metabolic Rate (BMR)

**Formula: Mifflin–St Jeor.** *Rationale:* widely regarded in nutrition guidance as the most
accurate common predictive equation for BMR in the general adult population, and it needs only
sex, weight, height, age.

```
BMR_male   = (10 × weight_kg) + (6.25 × height_cm) − (5 × age_years) + 5
BMR_female = (10 × weight_kg) + (6.25 × height_cm) − (5 × age_years) − 161
```

**Named constants:** `MSJ_WEIGHT=10`, `MSJ_HEIGHT=6.25`, `MSJ_AGE=5`, `MSJ_CONST_MALE=+5`,
`MSJ_CONST_FEMALE=−161`.

**Source:** Mifflin MD, St Jeor ST, et al., *A new predictive equation for resting energy
expenditure in healthy individuals*, Am J Clin Nutr, 1990.

### 2.3 `unspecified` sex — assumption
The Mifflin–St Jeor equation is sex-specific. When sex is `unspecified`, the engine uses the
**average of the male and female constants** (i.e., `(+5 + −161)/2 = −78`) and labels the result as
an estimate with reduced confidence. *This is an explicit assumption, not a guideline value.*
The UI offers the user the choice to specify sex for a more accurate estimate.

**Worked example** (female, 29 y, 165 cm, 71 kg):
`BMR = 10×71 + 6.25×165 − 5×29 − 161 = 710 + 1031.25 − 145 − 161 = 1435.25 kcal/day`.

---

## 3. Total Daily Energy Expenditure (TDEE)

**Formula:** `TDEE = BMR × PAL` (Physical Activity Level multiplier).

| `activity_level` | PAL multiplier | Description |
|---|---|---|
| `sedentary` | 1.2 | little/no exercise |
| `light` | 1.375 | light exercise 1–3 days/wk |
| `moderate` | 1.55 | moderate exercise 3–5 days/wk |
| `active` | 1.725 | hard exercise 6–7 days/wk |
| `very_active` | 1.9 | very hard exercise / physical job |

**Named constants:** `PAL_SEDENTARY=1.2` … `PAL_VERY_ACTIVE=1.9`.

**Source:** the Harris–Benedict activity-factor multipliers (1.2–1.9) are the conventional PAL
bands used with BMR to estimate TDEE; they are consistent with FAO/WHO/UNU PAL categories.
**Assumption:** exercise logged in `exercise_entry` is *not* double-counted into TDEE by default
(the PAL already accounts for typical activity); adding logged-exercise energy on top is an
optional, clearly-labeled setting to avoid double counting.

**Worked example** (BMR 1435.25, moderate): `TDEE = 1435.25 × 1.55 ≈ 2225 kcal/day`.

---

## 4. Calorie Goal

**Formula:** `CalorieGoal = TDEE + Adjustment(objective)`.

| Objective | Adjustment | Rationale |
|---|---|---|
| `maintain` | 0 | maintain current weight |
| `lose` | −`DEFICIT_KCAL` (default 500) | ≈ 0.45 kg/week loss (see §4.1) |
| `gain` | +`SURPLUS_KCAL` (default 300) | gradual, mostly-lean gain |

**Named constants:** `DEFICIT_KCAL=500`, `SURPLUS_KCAL=300` (both user-adjustable).

### 4.1 The 7,700 kcal/kg rule
A commonly used approximation is that **~7,700 kcal ≈ 1 kg** of body-fat energy (~3,500 kcal/lb).
A 500 kcal/day deficit ≈ 3,500 kcal/week ≈ **~0.45 kg/week**.
`ENERGY_PER_KG=7700`. **Assumption/caveat:** this is a simplification; real weight change is
non-linear and varies by individual. The engine states this as an *estimate* and never promises a
rate. **Safety floor:** the computed calorie goal is clamped to not fall below a configurable
minimum (`MIN_CALORIE_FLOOR`, default 1200 kcal/day) with a warning, to avoid encouraging
unsafe restriction. *This floor is a product safety choice, documented as such.*

**Source:** Wishnofsky's 3,500 kcal/lb approximation (widely cited; known to be an
oversimplification — hence the caveat and the safety floor).

---

## 5. Protein Goal

Protein is central to the mission ("Am I eating enough protein?"). We express it as a **range**
driven by weight and objective.

| Basis | g/kg body weight | When used |
|---|---|---|
| RDA baseline | 0.8 | sedentary maintenance minimum |
| Active/maintenance default | 1.2–1.6 | default band for most users |
| Muscle gain / higher activity | 1.6–2.0 | `gain` objective or `active`/`very_active` |

**Default target:** `ProteinGoal_g = weight_kg × PROTEIN_FACTOR`, where `PROTEIN_FACTOR` defaults
by profile (`1.2` sedentary → up to `2.0` very active/gain), clamped to `[0.8, 2.2]` g/kg.
User-overridable ([FR-6](02-requirements.md)).

**Named constants:** `PROTEIN_RDA=0.8`, `PROTEIN_DEFAULT_MIN=1.2`, `PROTEIN_DEFAULT_MAX=1.6`,
`PROTEIN_ATHLETE_MAX=2.0`, `PROTEIN_HARD_CAP=2.2`.

**Sources:** the 0.8 g/kg figure is the U.S./Institute of Medicine **RDA** for protein; the
1.2–2.0 g/kg ranges reflect widely cited sports-nutrition guidance (e.g., ACSM/ISSN position
stands) for active individuals and muscle gain. **Assumption:** targets use **total** body weight;
lean-body-mass-based targeting is a future refinement (needs body-fat input we don't collect in v1).

**Worked example** (71 kg, moderate/maintain, factor 1.4): `ProteinGoal = 71 × 1.4 ≈ 99 g/day`.

---

## 6. Macronutrient Split (Carbs / Fat / remaining energy)

After protein and calories, the remaining energy is split into carbs and fat by a
**configurable ratio** (default balanced): `carbs 45%`, `fat 30%`, `protein 25%` of calories, but
**protein is set by §5 first** and carbs/fat fill the remainder.

**Energy densities (Atwater):** `KCAL_PER_G_PROTEIN=4`, `KCAL_PER_G_CARB=4`, `KCAL_PER_G_FAT=9`,
`KCAL_PER_G_ALCOHOL=7` (tracked for completeness; alcohol not a v1 logging category).

Algorithm:
```
proteinKcal = ProteinGoal_g × 4
remaining   = CalorieGoal − proteinKcal
carbKcal    = remaining × CARB_SHARE     // default 0.60 of remaining
fatKcal     = remaining × FAT_SHARE      // default 0.40 of remaining
CarbGoal_g  = carbKcal / 4
FatGoal_g   = fatKcal / 9
```
**Named constants:** `CARB_SHARE=0.60`, `FAT_SHARE=0.40` (of the post-protein remainder;
user-adjustable). **Source:** Atwater general factors (4/4/9) are the standard energy conversions
used in nutrition labeling (FAO). The default macro shares are within the **Acceptable
Macronutrient Distribution Ranges (AMDR)**: carbs 45–65%, fat 20–35%, protein 10–35% of energy.

### 6.1 Fiber & Sugar targets
- **Fiber (minimum target):** `FIBER_PER_1000KCAL=14 g` → `FiberGoal = CalorieGoal/1000 × 14`.
  **Source:** Dietary Guidelines / IOM adequate intake (~14 g per 1,000 kcal).
- **Sugar (added-sugar ceiling):** `ADDED_SUGAR_MAX_PCT=0.10` of calories (a limit, not a target).
  **Source:** WHO recommends limiting free sugars to < 10% of total energy. Displayed as a ceiling
  with gentle framing, never a "goal to hit".

---

## 7. Water Goal

Two methods, cross-checked:

1. **Body-weight method (default):** `WaterGoal_ml = weight_kg × WATER_ML_PER_KG`,
   `WATER_ML_PER_KG=33` (common 30–35 ml/kg guidance). → 71 kg ≈ 2,343 ml.
2. **Energy method (sanity check):** ~1 ml per kcal consumed (IOM adequate-intake framing where
   total water ≈ energy expenditure in ml).

**Reference anchors (adequate total water intake, IOM/EFSA):** ~2.0 L/day (women) and ~2.5 L/day
(men) from *all* sources including food. The engine targets **beverage** water and clamps the
computed goal to a sensible band `[MIN_WATER_ML=1500, MAX_WATER_ML=4000]`.
**Assumption:** we count logged beverages, not water from food; the goal is a guide, not a medical
hydration prescription. User-overridable.

**Named constants:** `WATER_ML_PER_KG=33`, `MIN_WATER_ML=1500`, `MAX_WATER_ML=4000`.

---

## 8. Body Mass Index (BMI)

**Formula:** `BMI = weight_kg / (height_m)²`.

| BMI | WHO category |
|---|---|
| < 18.5 | Underweight |
| 18.5 – 24.9 | Normal |
| 25.0 – 29.9 | Overweight |
| ≥ 30.0 | Obese |

**Source:** WHO BMI classification for adults. **Caveat shown in-app:** BMI does not distinguish
muscle from fat and is a population screening tool, not a diagnosis — displayed with this note.

**Worked example** (71 kg, 1.65 m): `BMI = 71 / (1.65²) = 71 / 2.7225 ≈ 26.1 → Overweight`.

---

## 9. Health Score (0–100) — narrowly defined

> **Definition:** the Health Score is a **daily goal-adherence indicator**, *not* a verdict on the
> user's health. It answers "how close was I to my own goals today?" This narrow definition is a
> deliberate liability and honesty choice ([01](01-vision.md) §9).

**Formula:** a weighted average of per-goal adherence ratios, each capped at 1.0 (over-shooting a
target doesn't inflate the score; ceilings applied to "limit" metrics like added sugar).

```
adherence(metric) = clamp(actual / target, 0, 1)      // for "reach" goals
adherence(limit)  = clamp(1 − max(0, actual − limit)/limit, 0, 1)  // for "stay under" goals
Score = 100 × Σ (weight_i × adherence_i) / Σ weight_i
```

**Default weights** (sum normalized; user-adjustable):
| Component | Weight | Type |
|---|---|---|
| Calories within ±10% of goal | `W_CAL=0.25` | band |
| Protein target | `W_PROTEIN=0.25` | reach |
| Water target | `W_WATER=0.20` | reach |
| Fiber target | `W_FIBER=0.10` | reach |
| Added-sugar ceiling | `W_SUGAR=0.10` | limit |
| Logging completeness (did you log?) | `W_LOGGED=0.10` | reach |

**Rationale for weights:** protein and calories are the mission's headline metrics, hence the
largest weights; "logging completeness" gently rewards the habit that makes everything else work.
Weights are **defaults, fully documented, and user-tunable** — never hidden. The score is
explicitly labeled as goal-adherence in the UI.

**Named constants:** all weights above; `CAL_BAND_PCT=0.10`.

---

## 10. Determinism, Edge Cases & Safety

| Case | Behavior |
|---|---|
| Missing weight | Prompt user; do not fabricate. Metrics needing weight return `ValidationFailure`. |
| Age < 18 or > 100 | Compute but flag reduced confidence; formulas are validated for adults. |
| Extreme inputs (impossible height/weight) | Rejected by DB `CHECK` + domain validation ([04](04-database-design.md) §11). |
| Calorie goal below floor | Clamp to `MIN_CALORIE_FLOOR` with a safety warning. |
| Water goal outside band | Clamp to `[MIN_WATER_ML, MAX_WATER_ML]`. |
| Division by zero (no goal set) | Adherence component omitted from the score, weights renormalized. |

The engine is **pure** (same inputs → same outputs), enabling exhaustive unit tests, including the
worked examples in this document as fixtures ([11](11-testing-strategy.md)).

---

## 11. Constants Table (single source of truth)

| Constant | Value | Unit | Source/Note |
|---|---|---|---|
| `MSJ_*` | 10, 6.25, 5, +5, −161 | — | Mifflin–St Jeor (1990) |
| `PAL_*` | 1.2 / 1.375 / 1.55 / 1.725 / 1.9 | × | Harris–Benedict activity factors |
| `ENERGY_PER_KG` | 7700 | kcal/kg | Wishnofsky approximation (caveated) |
| `DEFICIT_KCAL` / `SURPLUS_KCAL` | 500 / 300 | kcal/day | default, user-adjustable |
| `MIN_CALORIE_FLOOR` | 1200 | kcal/day | product safety floor |
| `PROTEIN_*` | 0.8 / 1.2 / 1.6 / 2.0 / 2.2 | g/kg | RDA + sports-nutrition ranges |
| `KCAL_PER_G_*` | 4 / 4 / 9 / 7 | kcal/g | Atwater factors (FAO) |
| `CARB_SHARE` / `FAT_SHARE` | 0.60 / 0.40 | of remainder | within AMDR |
| `FIBER_PER_1000KCAL` | 14 | g | IOM adequate intake |
| `ADDED_SUGAR_MAX_PCT` | 0.10 | of energy | WHO free-sugar limit |
| `WATER_ML_PER_KG` | 33 | ml/kg | 30–35 ml/kg guidance |
| `MIN_WATER_ML` / `MAX_WATER_ML` | 1500 / 4000 | ml | safety band |
| BMI cutoffs | 18.5 / 25 / 30 | — | WHO classification |
| Health-score weights | see §9 | — | product defaults, user-tunable |

> All sources are public, general population-level guidance. Exact citations are to be pinned in
> code comments at implementation time; where a range exists, the chosen default and its rationale
> are recorded here. Any change to a constant is an [ADR](adr/0001-record-architecture-decisions.md).

---

*Next: [Phase 7 — AI Rules](07-ai-rules.md).*
