# Phase 7 — AI Rules (Health Assistant)

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [04](04-database-design.md), [06](06-health-rules.md). Feeds: [08](08-feature-specs.md).

**The AI is a Health Assistant, not a chatbot and not a doctor.** It analyzes patterns, generates
insights, detects trends, and explains — always with uncertainty, never with diagnosis. This
document specifies the v1 rule-based engine and the roadmap to on-device ML.

---

## 1. Principles (hard constraints)

1. **Analyze, don't diagnose.** Insights describe patterns in the user's *own* data. They never
   name diseases, never prescribe, never alarm. Forbidden output is enforced by the safety filter (§6).
2. **Always show uncertainty.** Every insight carries a confidence level ([FR-28](02-requirements.md)).
3. **Explainable by construction.** Every insight stores the evidence that produced it and can show
   its "why" ([FR-29](02-requirements.md)).
4. **Local-first.** v1 runs entirely on-device, offline, deterministic — no cloud LLM, consistent
   with the privacy promise ([01](01-vision.md)). ([ADR-0007](adr/0001-record-architecture-decisions.md#adr-0007))
5. **Data-honest.** No insight is produced without enough data (minimum sample thresholds, §4).
6. **User-controllable.** Insights can be dismissed and rated; the user is never nagged.

---

## 2. Why Rule-Based First (and not a cloud LLM)

| Option | Verdict | Reason |
|---|---|---|
| **Deterministic rule engine (on-device)** | **v1** | Private, offline, explainable, testable, zero inference cost, no hallucination risk on health data. |
| On-device small ML model | Roadmap | Better NL parsing / correlations once value is proven; behind a stable interface. |
| Cloud LLM | Rejected for core | Breaks offline + privacy promises; hallucination risk on health topics; ongoing cost. Could be an *opt-in* accessory later, clearly labeled, never required. |

"AI-Ready" means the **interfaces** (`InsightEngine`, `FoodTextParser`, `CorrelationAnalyzer`) are
defined now so a smarter implementation drops in later without touching the rest of the app.

---

## 3. Insight Types (v1 rule catalog)

Each rule has a stable `rule_id` (stored on `insight.rule_id`, [04](04-database-design.md) §4.7),
a trigger, a data window, a minimum-sample threshold, a confidence policy, and a message template.

| rule_id | Category | Fires when | Example message |
|---|---|---|---|
| `TREND_PROTEIN_UP` | Trend | 7-day protein-adherence rises vs. prior 7 days by ≥ threshold | "You hit your protein goal 5 of 7 days last week — up from 2." |
| `TREND_WEIGHT` | Trend | Moving-average weight slope over ≥ N days exceeds threshold | "Your weight trend is gently down (~0.3 kg/wk) this month." |
| `STREAK_WATER_MISS` | Streak | Water goal missed ≥ 3 consecutive days | "You've been under your water goal 4 days running." |
| `STREAK_LOG` | Streak/habit | Logged every day for ≥ 7 days | "7-day logging streak — nice consistency." |
| `CORR_FOOD_SYMPTOM` | Correlation | A food flag co-occurs with a symptom above chance over the window (§5) | "On days you logged 'dairy', you reported bloating more often (low confidence)." |
| `CORR_SLEEP_MOOD` | Correlation | Short-sleep days associate with lower mood over the window | "Your mood tends to be lower after nights under 6h (low confidence)." |
| `GOAL_PROTEIN_GAP` | Threshold | Weekly protein consistently < X% of goal | "You're averaging 62% of your protein goal this week." |
| `HYDRATION_TIMING` | Pattern | Most water logged late in the day | "Most of your water comes after 6pm — spreading it out may help." |

The catalog is **extensible**: adding a rule = adding a `rule_id` row here + a pure rule function
([09](09-folder-structure.md)) + tests. No schema change needed.

---

## 4. Data Sufficiency & Confidence Policy

Insights must not mislead from thin data.

| Confidence | Requires |
|---|---|
| **low** | Minimum viable sample met (e.g., ≥ 5 observations); pattern present but weak/short. |
| **medium** | Larger sample (e.g., ≥ 10–14 days) and a clearer effect. |
| **high** | Robust sample and a strong, stable effect (mostly for factual streaks/trends, not causal claims). |

- **Correlation insights are capped at `medium`** and default to `low` — correlation is never
  presented as causation. Copy always hedges ("tends to", "more often", "may").
- If sample thresholds aren't met, **no insight is generated** (silence over noise).
- Thresholds are **named constants** (`MIN_SAMPLE_CORR`, `TREND_DELTA_PCT`, `STREAK_MIN_DAYS`, …),
  documented and unit-tested — no magic numbers, mirroring [06](06-health-rules.md).

---

## 5. Correlation Method (v1, simple & honest)

v1 uses transparent, explainable statistics — not opaque ML:

1. Build daily series for the two variables over the window (e.g., food-flag present 0/1 vs.
   symptom severity, or sleep-hours bucket vs. mood).
2. Compare the target metric on "exposed" vs. "unexposed" days (difference in means / rates), and
   require a **minimum number of exposed days** (`MIN_EXPOSED_DAYS`).
3. Report only when the difference exceeds a documented effect-size threshold **and** the sample
   is sufficient; attach the counts as evidence.
4. Always label as association, `low`/`medium` confidence, with the explicit note that many factors
   affect symptoms and this is not a medical finding.

**Explicitly out of scope for v1:** multivariate models, p-value hunting across many pairs (which
would inflate false positives). The engine tests a **small, curated** set of physiologically
plausible pairs (food↔symptom, sleep↔mood, water↔energy) to avoid data dredging. This restraint is
a correctness and honesty decision, documented as such.

---

## 6. Safety Filter (mandatory output gate)

Before any insight is stored/shown, it passes a safety filter:

- **No diagnosis / disease naming.** A denylist + template-only generation means insights can only
  say what a template allows; free-form disease language is impossible by construction.
- **No prescriptions** ("take X", "you should stop eating Y forever"). Suggestions are gentle,
  reversible, and framed as experiments ("you could try…").
- **Disclaimer attached.** Every insight surface shows "informational, not medical advice"
  ([05](05-uiux-system.md) §5.5).
- **Red-flag routing (future, careful):** if the app ever detects patterns that warrant a clinician
  (e.g., rapid unexplained weight loss), the *only* action is a neutral suggestion to consider
  speaking with a healthcare professional — never a diagnosis. This is a roadmap item designed
  conservatively and gated behind review.

---

## 7. Natural-Language Food Logging ([FR-15](02-requirements.md))

An accelerator, never the only path ([05](05-uiux-system.md) §5.2).

- **Interface:** `FoodTextParser.parse(text) → List<ParsedFoodCandidate>` returning quantity +
  unit + a fuzzy match into `food_item`, each with a confidence.
- **v1 implementation:** a **deterministic parser** — tokenize, extract quantities/units
  (number words + digits), map remaining tokens to `food_item` via fuzzy/prefix search against the
  local food DB. No network, no LLM.
- **UX guardrail:** parsed results are **always shown for confirmation** before saving; low-confidence
  matches prompt the user to pick. The engine never silently logs the wrong food.
- **Roadmap:** swap the deterministic parser for an on-device NLU model behind the same interface.

---

## 8. Voice & Image Logging (roadmap — interfaces only)

Specified now so the architecture accommodates them; **not implemented in v1**.

| Capability | Interface | v1 status |
|---|---|---|
| Voice logging | `VoiceLogger` → speech-to-text → `FoodTextParser` | Interface defined; no implementation. On-device speech preferred for privacy. |
| Image recognition | `FoodImageRecognizer.recognize(image) → List<ParsedFoodCandidate>` | Interface defined; on-device model later; always user-confirmed. |

Both reuse the confirmation UX and the safety principles above.

---

## 9. Engine Placement & Execution

- The insight engine lives in the **domain/application** layers as pure functions over repository
  data ([03](03-architecture.md)) — testable without a device.
- **When it runs:** on a schedule (e.g., once per day) and on-demand (pull-to-refresh on the
  Insights screen). Heavy aggregation runs off the UI isolate ([03](03-architecture.md) §5).
- **Output:** `insight` rows ([04](04-database-design.md) §4.7) with `rule_id`, `confidence`,
  `evidence_json`, and the analyzed window — fully traceable.
- **Idempotency:** re-running for the same window updates rather than duplicates insights
  (keyed by `rule_id` + window).

---

## 10. Testing the AI ([11](11-testing-strategy.md))

- **Golden datasets:** hand-crafted logs with known patterns → assert exactly which insights fire,
  their confidence, and their evidence.
- **Negative tests:** thin/edge data → assert **no** insight (silence) and no false positives.
- **Safety tests:** assert the filter blocks any diagnosis/prescription phrasing and that every
  insight carries a confidence and disclaimer.
- **Determinism tests:** same input → identical output.

---

## 11. AI Risks

| Risk | Mitigation |
|---|---|
| Insight implies causation | Correlation capped at medium; hedged copy; explicit "association only" note. |
| False positives from data dredging | Curated, plausible pairs only; sample + effect-size thresholds. |
| Perceived as medical advice | Template-only generation; safety filter; persistent disclaimer. |
| Noise/nagging | Minimum-sample gating; dismissible; no repeat once dismissed. |
| Future ML breaks privacy | On-device only; any cloud option is opt-in, labeled, and never required. |

---

*Next: [Phase 8 — Feature Specifications](08-feature-specs.md).*
