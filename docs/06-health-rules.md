# Phase 6 — Health Rules (Rule-Based Health Engine)

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [02](02-requirements.md), [04](04-database-design.md). Feeds: [07](07-ai-rules.md), [08](08-feature-specs.md), [18](18-health-decision-engine.md).
> Science context lives in the [Knowledge Base](../knowledge/00-index.md); sources in [/research](../research/00-index.md).

The health engine turns profile + logs into targets and indicators. It is **deterministic and
rule-based** — no black boxes. **No magic numbers.**

> ⚠️ **Not medical advice.** These are population-level estimates for a *journaling* app —
> informational, user-adjustable, never a diagnosis or prescription. Surfaced in-app ([05 §5.5](05-uiux-system.md), [decisions/why-ai-is-not-a-doctor.md](../decisions/why-ai-is-not-a-doctor.md)).

**Engineering rule:** every constant maps to a **named** domain constant (no literals in code). The
engine is pure ([03](03-architecture.md)) and unit-tested ([11](11-testing-strategy.md)) against the
worked examples here.

### Per-Rule Template
Per the requirement that this document explain *why*, not just *how*, each rule below is structured as:
**Purpose · Scientific Background · Evidence · Formula · Assumptions · Limitations · Future Improvements.**

---

## 1. Inputs

| Input | Source | Notes |
|---|---|---|
| Sex | `user_profile.sex` | affects BMR; `unspecified` → see Rule 1 Assumptions |
| Age | derived from `birth_date` | years, floored |
| Height | `user_profile.height_cm` | cm |
| Weight | latest `weight_entry.weight_kg` | kg; falls back to a user-entered current weight |
| Activity level | `user_profile.activity_level` | maps to a PAL multiplier (Rule 2) |
| Objective | active `goal.objective` | maintain / lose / gain |

If a required input is missing, the engine returns a typed `ValidationFailure` and the UI prompts for
it — it never guesses silently.

---

## Rule 1 — Basal Metabolic Rate (BMR)

- **Purpose.** Estimate the energy the body uses at complete rest — the foundation of every calorie
  target.
- **Scientific Background.** BMR is the largest component of daily energy use. Predictive equations
  estimate it from sex, weight, height, and age. Mifflin–St Jeor is widely regarded as the most
  accurate common equation for the general adult population. See [knowledge/weight_loss.md](../knowledge/weight_loss.md).
- **Evidence.** **A** (validated equation). Source: Mifflin–St Jeor (1990) → [research/research-papers.md](../research/research-papers.md).
- **Formula.**
  ```
  BMR_male   = (10 × weight_kg) + (6.25 × height_cm) − (5 × age_years) + 5
  BMR_female = (10 × weight_kg) + (6.25 × height_cm) − (5 × age_years) − 161
  ```
  Named constants: `MSJ_WEIGHT=10`, `MSJ_HEIGHT=6.25`, `MSJ_AGE=5`, `MSJ_CONST_MALE=+5`, `MSJ_CONST_FEMALE=−161`.
  *Worked example* (female, 29 y, 165 cm, 71 kg): `710 + 1031.25 − 145 − 161 = 1435.25 kcal/day`.
- **Assumptions.** For `sex = unspecified`, the engine uses the **average** of the male/female
  constants (`(+5 + −161)/2 = −78`) and flags reduced confidence; the UI invites specifying sex.
- **Limitations.** Population estimate; individual metabolism varies (±~10%). Validated for adults;
  less reliable at age extremes and for very high muscle mass.
- **Future Improvements.** Optional Katch–McArdle equation when body-fat % is available (lean-mass
  based); recalibration against the user's observed weight trend.

---

## Rule 2 — Total Daily Energy Expenditure (TDEE)

- **Purpose.** Scale BMR up to real daily expenditure including activity — the basis of the calorie goal.
- **Scientific Background.** TDEE = BMR × a Physical Activity Level (PAL) multiplier reflecting typical
  activity. See [knowledge/exercise.md](../knowledge/exercise.md).
- **Evidence.** **B** (conventional activity factors). Source: Harris–Benedict PAL bands, consistent
  with FAO/WHO/UNU categories → [research/research-papers.md](../research/research-papers.md).
- **Formula.** `TDEE = BMR × PAL`
  | `activity_level` | PAL | |
  |---|---|---|
  | `sedentary` | 1.2 | little/no exercise |
  | `light` | 1.375 | 1–3 days/wk |
  | `moderate` | 1.55 | 3–5 days/wk |
  | `active` | 1.725 | 6–7 days/wk |
  | `very_active` | 1.9 | very hard / physical job |

  Named constants: `PAL_SEDENTARY=1.2` … `PAL_VERY_ACTIVE=1.9`.
  *Worked example* (BMR 1435.25, moderate): `1435.25 × 1.55 ≈ 2225 kcal/day`.
- **Assumptions.** Logged exercise is **not** double-counted by default — PAL already includes typical
  activity; adding logged-exercise energy is an optional, labeled setting ([knowledge/exercise.md](../knowledge/exercise.md)).
- **Limitations.** Self-selected activity level is subjective; PAL bands are coarse.
- **Future Improvements.** Derive activity from Health Connect/wearable data ([15](15-release-roadmap.md))
  instead of a self-reported band.

---

## Rule 3 — Calorie Goal

- **Purpose.** Turn TDEE + the user's objective into a daily calorie target.
- **Scientific Background.** Weight change is driven by energy balance ([knowledge/weight_loss.md](../knowledge/weight_loss.md)).
  A deficit/surplus adjusts the maintenance (TDEE) figure.
- **Evidence.** Energy-balance principle **A**; the kcal-per-kg rate estimate **C** (approximation).
- **Formula.** `CalorieGoal = TDEE + Adjustment(objective)`
  | Objective | Adjustment |
  |---|---|
  | `maintain` | 0 |
  | `lose` | −`DEFICIT_KCAL` (default 500) → ≈ 0.45 kg/wk |
  | `gain` | +`SURPLUS_KCAL` (default 300) |

  The **7,700 kcal ≈ 1 kg** approximation (`ENERGY_PER_KG=7700`, ~3,500 kcal/lb) links a 500 kcal/day
  deficit to ~0.45 kg/week. Named constants: `DEFICIT_KCAL=500`, `SURPLUS_KCAL=300`.
- **Assumptions / Safety.** Real weight change is non-linear; the engine states an *estimate*, never a
  promise. The goal is clamped to a safety floor `MIN_CALORIE_FLOOR=1200 kcal/day` (with a warning) to
  avoid encouraging unsafe restriction — a documented **product safety** choice.
- **Limitations.** Wishnofsky's 7,700 kcal/kg is a known oversimplification (Evidence **C**) →
  [research/research-papers.md](../research/research-papers.md).
- **Future Improvements.** Adaptive calorie goals that self-correct from the observed weight trend
  ([18 Trend Evaluation](18-health-decision-engine.md)).

---

## Rule 4 — Protein Goal

- **Purpose.** Answer the mission question *"am I eating enough protein?"* with a personalized target.
- **Scientific Background.** Protein needs scale with body weight and activity; higher intakes support
  muscle preservation and satiety. See [knowledge/protein.md](../knowledge/protein.md).
- **Evidence.** RDA **A**; active-range targets **B** → [research/dietary-guidelines.md](../research/dietary-guidelines.md), [research/research-papers.md](../research/research-papers.md).
- **Formula.** `ProteinGoal_g = weight_kg × PROTEIN_FACTOR`, factor defaulting by profile
  (`1.2` sedentary → `2.0` very active/gain), clamped to `[0.8, 2.2]` g/kg. User-overridable ([FR-6](02-requirements.md)).
  Named constants: `PROTEIN_RDA=0.8`, `PROTEIN_DEFAULT_MIN=1.2`, `PROTEIN_DEFAULT_MAX=1.6`,
  `PROTEIN_ATHLETE_MAX=2.0`, `PROTEIN_HARD_CAP=2.2`.
  *Worked example* (71 kg, factor 1.4): `≈ 99 g/day`.
- **Assumptions.** Targets use **total** body weight (lean-mass targeting needs body-fat data we don't
  collect in v1).
- **Limitations.** Ranges are population guidance; individual needs vary. Clinical kidney conditions
  are out of scope — the app defers to clinicians.
- **Future Improvements.** Lean-body-mass targeting when body-fat % exists; per-meal distribution insights.

---

## Rule 5 — Macronutrient Split (Carbs / Fat)

- **Purpose.** Allocate the remaining energy (after protein) into carbohydrate and fat targets.
- **Scientific Background.** Energy from macros uses Atwater factors; healthy ranges follow the AMDR.
  See [knowledge/carbohydrates.md](../knowledge/carbohydrates.md), [knowledge/fat.md](../knowledge/fat.md).
- **Evidence.** Atwater factors **A**; AMDR **A** → [research/usda.md](../research/usda.md), [research/dietary-guidelines.md](../research/dietary-guidelines.md).
- **Formula.**
  ```
  proteinKcal = ProteinGoal_g × 4
  remaining   = CalorieGoal − proteinKcal
  CarbGoal_g  = (remaining × CARB_SHARE) / 4   // CARB_SHARE=0.60 of remainder
  FatGoal_g   = (remaining × FAT_SHARE) / 9    // FAT_SHARE=0.40 of remainder
  ```
  Energy densities: `KCAL_PER_G_PROTEIN=4`, `KCAL_PER_G_CARB=4`, `KCAL_PER_G_FAT=9`, `KCAL_PER_G_ALCOHOL=7`.
  Defaults sit within AMDR (carbs 45–65%, fat 20–35%, protein 10–35% of energy).
- **Assumptions.** Protein is set first (Rule 4); carbs/fat fill the remainder; shares are user-adjustable.
- **Limitations.** Macro ratios are preference/adherence choices, not a health mandate within AMDR.
- **Future Improvements.** Goal presets (e.g., higher-carb for endurance) with documented rationale.

### Rule 5b — Fiber & Sugar
- **Fiber (target).** `FiberGoal = CalorieGoal/1000 × FIBER_PER_1000KCAL` (`=14 g`). Evidence **A/B**,
  IOM AI → [knowledge/fiber.md](../knowledge/fiber.md). *Future:* soluble/insoluble split.
- **Added Sugar (ceiling, not a goal).** `ADDED_SUGAR_MAX_PCT=0.10` of energy. Evidence **A**, WHO
  free-sugars → [research/who.md](../research/who.md), [knowledge/carbohydrates.md](../knowledge/carbohydrates.md).
  Displayed gently as a limit. *Limitation:* distinguishing added vs. natural sugars depends on food-DB data quality ([17](17-food-database.md)).

---

## Rule 6 — Water Goal

- **Purpose.** Personalize a daily hydration target ([knowledge/water.md](../knowledge/water.md)).
- **Scientific Background.** Needs scale with body size (and activity/climate); ~30–35 ml/kg is common
  guidance, cross-checked against total-water adequate-intake anchors.
- **Evidence.** Body-weight method **B**; AI anchors **B** → [research/dietary-guidelines.md](../research/dietary-guidelines.md).
- **Formula.** `WaterGoal_ml = weight_kg × WATER_ML_PER_KG` (`=33`), clamped to
  `[MIN_WATER_ML=1500, MAX_WATER_ML=4000]`. *Worked example* (71 kg): `≈ 2343 ml`. Sanity cross-check:
  ~1 ml/kcal.
- **Assumptions.** Counts **beverage** water (not water from food); a guide, not a medical prescription.
- **Limitations.** Ignores climate/illness/pregnancy adjustments; overriding is expected. Excess water
  risk (hyponatremia) is why the band is clamped ([knowledge/water.md](../knowledge/water.md)).
- **Future Improvements.** Climate/activity adjustment; timing guidance (`HYDRATION_TIMING`, [07](07-ai-rules.md)).

---

## Rule 7 — Body Mass Index (BMI)

- **Purpose.** Provide a simple weight-status screen — clearly labeled as screening, not diagnosis.
- **Scientific Background.** BMI classifies weight-for-height at population level ([knowledge/bmi.md](../knowledge/bmi.md)).
- **Evidence.** **A** (WHO classification) → [research/who.md](../research/who.md).
- **Formula.** `BMI = weight_kg / (height_m)²`
  | BMI | Category | | BMI | Category |
  |---|---|---|---|---|
  | <18.5 | Underweight | | 25.0–29.9 | Overweight |
  | 18.5–24.9 | Normal | | ≥30.0 | Obese |

  *Worked example* (71 kg, 1.65 m): `≈ 26.1 → Overweight`.
- **Assumptions.** Adult cut-offs; a screening ratio only.
- **Limitations.** **Cannot distinguish muscle from fat**; ignores distribution/ethnicity — a mandatory
  in-app caveat.
- **Future Improvements.** Waist-based metrics; ethnicity-specific action points (with sources).

---

## Rule 8 — Health Score (0–100)

- **Purpose.** A single, glanceable **daily goal-adherence** indicator — motivational, honest, tunable.
- **Scientific Background / Rationale.** Deliberately defined as *adherence to the user's own goals*,
  **not** a medical verdict — a liability and honesty choice ([decisions/why-health-score-exists.md](../decisions/why-health-score-exists.md)).
- **Evidence.** Design decision (not a clinical measure); components trace to Rules 3–6.
- **Formula.**
  ```
  adherence(reach) = clamp(actual / target, 0, 1)
  adherence(limit) = clamp(1 − max(0, actual − limit)/limit, 0, 1)
  Score = 100 × Σ(weight_i × adherence_i) / Σ weight_i
  ```
  Default weights (user-tunable): `W_CAL=0.25` (±10% band, `CAL_BAND_PCT=0.10`), `W_PROTEIN=0.25`,
  `W_WATER=0.20`, `W_FIBER=0.10`, `W_SUGAR=0.10` (limit), `W_LOGGED=0.10`.
- **Assumptions.** Over-shooting a reach goal is capped at 1.0 (can't be gamed); missing goals are
  dropped and weights renormalized. Computed by the [Decision Engine](18-health-decision-engine.md).
- **Limitations.** Not a health assessment; depends on the goals being sensible (hence Rules 1–6 + floors).
- **Future Improvements.** Optional weekly score smoothing; user-defined components.

---

## 10. Determinism, Edge Cases & Safety

| Case | Behavior |
|---|---|
| Missing weight | Prompt; do not fabricate. Metrics needing weight return `ValidationFailure`. |
| Age < 18 or > 100 | Compute but flag reduced confidence; equations validated for adults. |
| Extreme inputs | Rejected by DB `CHECK` + domain validation ([04 §11](04-database-design.md)). |
| Calorie goal below floor | Clamp to `MIN_CALORIE_FLOOR` with a safety warning. |
| Water goal outside band | Clamp to `[MIN_WATER_ML, MAX_WATER_ML]`. |
| No goal set (÷0) | Component omitted from the score; weights renormalized. |

The engine is **pure** (same inputs → same outputs); the worked examples above are unit-test fixtures
([11 §3.1](11-testing-strategy.md)).

---

## 11. Constants Table (single source of truth)

| Constant | Value | Unit | Source/Note |
|---|---|---|---|
| `MSJ_*` | 10, 6.25, 5, +5, −161 | — | Mifflin–St Jeor (1990) |
| `PAL_*` | 1.2 / 1.375 / 1.55 / 1.725 / 1.9 | × | Harris–Benedict activity factors |
| `ENERGY_PER_KG` | 7700 | kcal/kg | Wishnofsky approximation (caveated, **C**) |
| `DEFICIT_KCAL` / `SURPLUS_KCAL` | 500 / 300 | kcal/day | default, user-adjustable |
| `MIN_CALORIE_FLOOR` | 1200 | kcal/day | product safety floor |
| `PROTEIN_*` | 0.8 / 1.2 / 1.6 / 2.0 / 2.2 | g/kg | RDA + sports-nutrition ranges |
| `KCAL_PER_G_*` | 4 / 4 / 9 / 7 | kcal/g | Atwater factors (FAO/USDA) |
| `CARB_SHARE` / `FAT_SHARE` | 0.60 / 0.40 | of remainder | within AMDR |
| `FIBER_PER_1000KCAL` | 14 | g | IOM adequate intake |
| `ADDED_SUGAR_MAX_PCT` | 0.10 | of energy | WHO free-sugar limit |
| `WATER_ML_PER_KG` | 33 | ml/kg | 30–35 ml/kg guidance |
| `MIN_WATER_ML` / `MAX_WATER_ML` | 1500 / 4000 | ml | safety band |
| BMI cutoffs | 18.5 / 25 / 30 | — | WHO classification |
| Health-score weights | see Rule 8 | — | product defaults, user-tunable |

> Sources are public, population-level guidance registered in [/research](../research/00-index.md);
> exact citations are pinned (and `[verify]` tags resolved) before any figure appears in-app. Any
> change to a constant is an [ADR](adr/0001-record-architecture-decisions.md).

---

*Next: [Phase 7 — AI Rules](07-ai-rules.md).*
