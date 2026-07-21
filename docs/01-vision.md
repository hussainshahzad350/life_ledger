# Phase 1 — Project Vision

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: nothing. Feeds: everything.

---

## 1. Mission

**Build a Personal Health Operating System that helps people understand their body through
long-term patterns — not by counting calories, but by connecting cause and effect over time.**

LifeLedger records the small daily facts of a life — what you ate, how you slept, how you
felt, what your body did — and turns that ledger into understanding. The product's north
star is a single sentence a user can say after a month of use:

> *"Now I understand why I feel the way I do."*

---

## 2. The Problems We Solve

Existing apps answer *"how many calories did I eat?"*. LifeLedger answers the questions people
actually ask about their bodies:

- Why am I always hungry?
- Why do I gain (or lose) weight?
- Am I eating enough protein?
- Which foods make me feel better — and which make me feel worse?
- Which foods cause digestive issues?
- Am I drinking enough water?
- Which habits actually improve my health over time?

The differentiator: **LifeLedger discovers answers through the user's own data, not through
generic assumptions.** It surfaces correlations and trends the user could never spot manually.

---

## 3. Product Philosophy

Every decision is ranked against these priorities, **in order**:

1. **Simplicity** — the app must be usable in seconds, not studied.
2. **Accuracy** — if we show a number, it must be defensible and sourced.
3. **Privacy** — the user's body data never leaves their device without explicit consent.
4. **Performance** — it must feel instant on a mid-range Android phone.
5. **Maintainability** — a new engineer should be productive in a week.
6. **Scalability** — new trackers and insights must slot in without rework.
7. **User Experience** — delight is the reward for getting the first six right.

> **Feature-justification rule:** every feature must increase user value more than it increases
> complexity. If it does not, it is rejected — no matter how "cool" it is. This is enforced in
> [`08-feature-specs.md`](08-feature-specs.md) where each feature states its justification.

---

## 4. Explicit Non-Goals

Stating what we will **not** build is as important as what we will.

| Non-goal | Why |
|---|---|
| Calorie-counting-as-the-point | Calories are one signal among many, not the product. |
| Diet plans / meal prescriptions | We describe the user's body; we don't prescribe diets. |
| Social feed / gamified competition | Health is personal; comparison harms more than it helps. |
| Medical diagnosis | We are not a medical device. We inform; clinicians diagnose. |
| Advertising / data monetization | Ads and data-selling are incompatible with privacy-first. |
| Mandatory cloud account | The app is fully functional with no account and no network. |
| Weight-loss "quick fix" framing | We optimize for understanding, not vanity metrics. |

---

## 5. Target Users (Personas)

These personas drive requirements and UX. Each real requirement traces to at least one persona.

### Persona A — "Curious Maya" (Primary)
- 29, office worker, moderately health-conscious, not an athlete.
- **Goal:** understand why her energy and weight fluctuate.
- **Frustration:** existing apps demand tedious logging and give shallow feedback.
- **Needs:** fast logging, meaningful weekly insights, no judgment, privacy.

### Persona B — "Managing Sam" (Primary)
- 45, living with a manageable condition (e.g., IBS-type sensitivity, pre-diabetes risk).
- **Goal:** identify which foods trigger symptoms and track trends to discuss with a doctor.
- **Frustration:** can't correlate symptoms with foods across weeks.
- **Needs:** symptom + food logging, correlation insights, exportable reports, strict privacy.

### Persona C — "Deliberate Dev" (Secondary)
- 34, quantified-self enthusiast.
- **Goal:** own their data, tweak goals precisely, export/analyze.
- **Needs:** configurable targets, data export/import, transparency in every calculation.

### Persona D — "Future Wearable Wanda" (Roadmap)
- Uses a smartwatch and Android Health Connect.
- **Goal:** passive capture (steps, sleep, heart rate) feeding the same journal.
- **Needs:** Health Connect + Wear OS integration (post-v1; see [12](12-implementation-plan.md)).

---

## 6. The Core User Experience Promise

The dashboard must instantly answer, without scrolling or tapping:

- How many **calories** today (and how many remaining)?
- How much **protein** today (and target)?
- How much **water** today (and target)?
- What's my **weight trend**?
- What's my **health score** today?

And the primary action — logging a meal — must take **under 10 seconds** including app launch.

---

## 7. Success Metrics

We measure success by understanding delivered, not vanity engagement. Because the app is
privacy-first and analytics-free, these are **product design targets** validated in usability
testing and optional, explicitly-consented, on-device self-reporting — never silent telemetry.

| Metric | Target | Rationale |
|---|---|---|
| Time to log breakfast (cold) | < 10 s | Core simplicity promise. |
| Dashboard cold-start | ≤ 1.5 s | Feels instant. |
| Days-to-first-insight | ≤ 7 days of logging | Insight is the payoff; it must arrive quickly. |
| Retention proxy (self-reported) | User can name one thing they learned in month 1 | The mission, made measurable. |
| Data portability | 100% of data exportable/importable | Ownership is non-negotiable. |
| Crash-free sessions | ≥ 99.5% | Trust in a health record demands stability. |

---

## 8. Risks & Mitigations (Vision-Level)

| Risk | Impact | Mitigation |
|---|---|---|
| Logging friction kills retention | High | Obsess over the < 10 s promise; quick-add, recents, favorites ([05](05-uiux-system.md)). |
| Insights feel generic or wrong | High | Rule-based, transparent, uncertainty-flagged insights ([07](07-ai-rules.md)). |
| Scope creep dilutes the product | Medium | Feature-justification rule + explicit non-goals. |
| Health claims create liability | High | Never diagnose; disclaimers; sourced formulas ([06](06-health-rules.md), [07](07-ai-rules.md)). |
| Privacy promise broken by a dependency | High | No analytics/ad SDKs; dependency review in [10](10-coding-standards.md). |
| Data loss destroys trust | High | Robust migrations, backup/restore, export ([04](04-database-design.md)). |

---

## 9. Architect's Challenge to the Brief

Per the mandate to challenge assumptions, three notes carried into later phases:

1. **"AI-Ready" ≠ "AI-now".** Shipping a cloud LLM would break the privacy promise. v1's "AI"
   is a deterministic, on-device, rule-based insight engine. True ML is a *roadmap* capability
   behind a stable interface. Justified in [`07-ai-rules.md`](07-ai-rules.md).
2. **Health scoring is a liability surface.** A single "health score" risks being read as
   medical judgment. We define it narrowly as a *goal-adherence* score with explicit
   disclaimers, not a verdict on health. Defined in [`06-health-rules.md`](06-health-rules.md).
3. **Offline-first shapes the schema, not just the network layer.** Every table is designed
   sync-ready from day one (soft-deletes, timestamps, sync columns) so that optional cloud sync
   never forces a breaking migration. Justified in [`04-database-design.md`](04-database-design.md).

---

*Next: [Phase 2 — Requirements](02-requirements.md).*
