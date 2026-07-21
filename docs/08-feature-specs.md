# Phase 8 — Feature Specifications

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [03](03-architecture.md)–[07](07-ai-rules.md). Feeds: [09](09-folder-structure.md), [11](11-testing-strategy.md), [12](12-implementation-plan.md).

Each feature is specified with a fixed template: **Purpose → Justification → Business Rules → Data
(DB impact) → UI/Navigation → Validation → Error Handling → Future Evolution**. The **Future
Evolution** line shows each feature's growth ladder (e.g., Food Logging: V1 → Voice → Image → …), so
today's simple feature has a documented path to its ambitious future without over-building now. Every feature
traces to requirements ([02](02-requirements.md)), tables ([04](04-database-design.md)), screens
([05](05-uiux-system.md)), and rules ([06](06-health-rules.md)/[07](07-ai-rules.md)). This
traceability is the consistency contract of the whole spec.

**Traceability matrix (feature → table → screen → rules → requirements):**

| Feature | Tables | Screen(s) | Rules | Reqs |
|---|---|---|---|---|
| F1 Profile | `user_profile` | Onboarding, Profile | Rules 1–2,7 (health) | FR-1..4 |
| F2 Goals | `goal` | Goals, Onboarding | Rules 3–8 (health) | FR-5..8 |
| F3 Food logging | `food_item`,`food_entry` | Quick Add, Journal | Rule 5 (health), §7 (AI parse) | FR-9..16 |
| F4 Water | `water_entry` | Dashboard, Quick Add | Rule 6 (health) | FR-17 |
| F5 Weight | `weight_entry` | Dashboard, Weight detail | Rules 3,7 (health) | FR-18 |
| F6 Sleep | `sleep_entry` | Journal, Reports | §5 (AI corr) | FR-19 |
| F7 Mood | `mood_entry` | Journal, Reports | §5 (AI corr) | FR-20 |
| F8 Symptoms | `symptom_entry`,`symptom_type` | Journal, Reports | §5 (AI corr) | FR-21 |
| F9 Exercise | `exercise_entry` | Journal, Reports | Rule 2 (health) | FR-22 |
| F10 Dashboard | (reads all) | Dashboard | Rule 8 health score | FR-24..26 |
| F11 Insights | `insight` | Insights | all of [07](07-ai-rules.md) | FR-27..30 |
| F12 Reports | (reads all) | Reports | health/AI | FR-31..33 |
| F13 Notifications | `app_meta` | Settings | — | FR-34,35 |
| F14 Backup/Export | (all) + `app_meta` | Settings | — | FR-36..39 |
| F15 Settings | `user_profile`,`app_meta` | Settings | — | FR-40..42 |

---

## F1 — User Profile
- **Purpose.** Capture the minimum body data needed to personalize goals and metrics.
- **Justification.** Without sex/age/height/weight the health engine can't compute BMR/TDEE/BMI ([06](06-health-rules.md)). Kept minimal to honor privacy and simplicity.
- **Business rules.** Metric stored canonically ([04](04-database-design.md) §2); editing recomputes dependent goals; profile is skippable with defaults ([FR-4](02-requirements.md)).
- **Data.** `user_profile` (single row v1). Height in cm, canonical.
- **UI/Nav.** Onboarding step 2; editable from More → Profile ([05](05-uiux-system.md) §5.6).
- **Validation.** Height 0–300 cm; birth date not in the future; sex ∈ enum. Domain value objects enforce before persist.
- **Errors.** `ValidationFailure` surfaced inline; `DatabaseFailure` → retry with message.
- **Future Evolution.** Single profile → **multi-profile** (schema-ready, [04 §3](04-database-design.md)) → **body-fat %** (lean-mass protein targeting, [06 Rule 4](06-health-rules.md)) → **Health Connect import** → **Family Mode** ([15](15-release-roadmap.md)).

## F2 — Goals
- **Purpose.** Define the targets the whole app measures against.
- **Justification.** Goals turn raw logs into "remaining"/adherence — the dashboard's core value.
- **Business rules.** System-proposed defaults from the engine ([06](06-health-rules.md)); user overrides flagged `source='user'`; **versioned** (close old, insert new) for historical report accuracy ([04](04-database-design.md) §4.2, [FR-8](02-requirements.md)).
- **Data.** `goal` (versioned rows).
- **UI/Nav.** Goals screen; preview during onboarding.
- **Validation.** Targets within safety bands (calorie floor [06 Rule 3](06-health-rules.md); water band [06 Rule 6](06-health-rules.md)); objective ∈ enum.
- **Errors.** Below-floor calorie goal → clamp + warning; conflicting active goals prevented by the close-then-insert rule.
- **Future Evolution.** Manual/default goals → **goal templates** → **adaptive goals** that self-correct from the weight trend ([18 Trend Evaluation](18-health-decision-engine.md)) → **AI-personalized goals** ([07 Phase 4](07-ai-rules.md)).

## F3 — Food & Meal Logging (core)
- **Purpose.** Fast, low-friction recording of what the user eats.
- **Justification.** The product's most-used action; the < 10 s promise ([FR-10](02-requirements.md)) lives here.
- **Business rules.** Entry = `food_item` × `quantity` in a `meal_slot`; nutrition derived ([04](04-database-design.md) §9); `local_date` stamped at write for correct day grouping; soft-delete + Undo.
- **Data.** `food_item` (seed + custom + favorites), `food_entry`. Indexes `idx_food_entry_user_date` ([04](04-database-design.md) §6).
- **UI/Nav.** Quick Add opens on Recents/Favorites; meal slot auto-selected by time; stepper quantity; optional NL parse ([07](07-ai-rules.md) §7). Journal timeline groups by meal ([05](05-uiux-system.md) §5.3).
- **Validation.** Quantity > 0; nutrition ≥ 0; custom food requires name + serving. NL results always user-confirmed.
- **Errors.** No match in NL parse → prompt to search/create; save failure rolls back optimistic UI.
- **Future Evolution.** **V1 (tap/search)** → **Voice logging** → **Image logging** → **AI recognition** → **Restaurant OCR** → **Barcode** → **Wear OS** — all behind the `FoodTextParser`/`FoodImageRecognizer` interfaces ([07 §7/§8](07-ai-rules.md)), plus nutrition-snapshot-on-entry ([04 §9](04-database-design.md)) and recipes ([17 §2.10](17-food-database.md)).

## F4 — Water
- **Purpose.** One-tap hydration logging.
- **Justification.** Answers "am I drinking enough water?"; extremely low friction → high adherence.
- **Business rules.** Increment by configurable unit (e.g., 250 ml); goal from engine ([06 Rule 6](06-health-rules.md)); day-grouped by `local_date`.
- **Data.** `water_entry`.
- **UI/Nav.** Dashboard quick-add chip (`💧 +250`) and detail screen.
- **Validation.** amount > 0; clamp daily goal to band.
- **Errors.** Standard soft-delete/Undo; `DatabaseFailure` handling.
- **Future Evolution.** One-tap water → **beverage types** → **caffeine tracking** → **pace-based reminders** (`HYDRATION_TIMING`, [07](07-ai-rules.md)) → **Wear OS** quick-add.

## F5 — Weight
- **Purpose.** Track weight and its trend (not single readings).
- **Justification.** Answers "why do I gain/lose weight?"; trend > noise.
- **Business rules.** Store kg canonical; compute **moving-average trend** (not raw jitter) for display and the `TREND_WEIGHT` insight ([07](07-ai-rules.md)).
- **Data.** `weight_entry`, index `idx_weight_user_date`.
- **UI/Nav.** Dashboard card + line chart with moving average ([05](05-uiux-system.md) §5.4).
- **Validation.** 0 < kg < 700 (DB CHECK + domain).
- **Errors.** Duplicate same-day entries allowed (keep latest for "current"); standard failures.
- **Future Evolution.** Manual weight → **body measurements** → **body-fat %** → **smart-scale / Health Connect sync** → **AI trend forecasting** (descriptive, never predictive-as-fact).

## F6 — Sleep
- **Purpose.** Record sleep duration/quality for correlation with mood/energy.
- **Business rules.** Duration from start/end or entered directly; quality 1–5 optional; day attribution rule = the wake date's `local_date`.
- **Data.** `sleep_entry`.
- **UI/Nav.** Journal quick entry; Reports charts.
- **Validation.** end ≥ start; duration ≥ 0; quality 1–5.
- **Errors.** Overnight spanning handled by attribution rule; standard failures.
- **Future Evolution.** Manual sleep → **quality/stages detail** → **auto-capture via Health Connect/wearable** ([01](01-vision.md) Persona D) → **Wear OS** sleep sync.

## F7 — Mood
- **Purpose.** Lightweight subjective wellbeing signal.
- **Business rules.** Ordinal 1–5 + optional note; feeds `CORR_SLEEP_MOOD` ([07](07-ai-rules.md) §5).
- **Data.** `mood_entry`. **UI/Nav.** Journal emoji selector; Reports trend.
- **Validation.** mood ∈ 1..5. **Errors.** standard.
- **Future Evolution.** Simple 1–5 mood → **tags** (stress, energy) → **time-of-day mood** → **richer mood↔lifestyle correlations** ([07](07-ai-rules.md), honesty-capped).

## F8 — Symptoms
- **Purpose.** Track symptoms to find food/lifestyle associations.
- **Justification.** Persona B's core need ("which foods cause digestive issues?").
- **Business rules.** Typed via `symptom_type` (seeded + user-added); severity 1–5; feeds `CORR_FOOD_SYMPTOM` with strict honesty rules ([07](07-ai-rules.md) §5/§6).
- **Data.** `symptom_entry`, `symptom_type`.
- **UI/Nav.** Journal quick entry; pattern report overlays symptom vs. food flag.
- **Validation.** severity ∈ 1..5; symptom_type FK valid.
- **Errors.** standard; correlation only when sample sufficient.
- **Future Evolution.** Typed symptoms → **symptom clusters** → **medication correlation** (with future medication tracking) → **exportable clinician report** ([15 Doctor Portal](15-release-roadmap.md)) — always association-only ([knowledge/symptoms.md](../knowledge/symptoms.md)).

## F9 — Exercise
- **Purpose.** Record activity for context (not a fitness tracker).
- **Business rules.** Type + duration (+ optional intensity/energy). By default **not** added to TDEE to avoid double-counting ([06 Rule 2](06-health-rules.md)); optional labeled toggle to include.
- **Data.** `exercise_entry`. **UI/Nav.** Journal entry; Reports.
- **Validation.** duration ≥ 0; intensity ∈ enum. **Errors.** standard.
- **Future Evolution.** Manual exercise → **step count** → **Health Connect activity import** → **Wear OS** live capture (still not a fitness-tracker product, [01](01-vision.md)).

## F10 — Dashboard
- **Purpose.** Answer the five questions instantly ([FR-24](02-requirements.md)).
- **Justification.** The at-a-glance promise is the product's face.
- **Business rules.** Reads today's aggregates (SQL `GROUP BY local_date`) + active goals + latest weight trend + Health Score ([06 Rule 8](06-health-rules.md)) + latest insight.
- **Data.** Reads across log tables via indexed queries; no writes.
- **UI/Nav.** Home tab; each metric tappable to detail ([05](05-uiux-system.md) §5.1).
- **Performance.** Cold start ≤ 1.5 s ([NFR-1](02-requirements.md)) via indexed aggregate queries + skeleton loading.
- **Errors.** Partial-data days render gracefully (empty states); a failed metric shows a retry chip, not a blank dashboard.
- **Future Evolution.** In-app dashboard → **home-screen widget** → **Wear OS glanceable** → **personalized layout** (user picks metrics).

## F11 — Insights
- **Purpose.** Deliver the "understanding" payoff ([07](07-ai-rules.md)).
- **Business rules.** Rule engine generates `insight` rows with confidence + evidence; safety filter mandatory; dismissible; feedback stored.
- **Data.** `insight` (`idx_insight_user_period`).
- **UI/Nav.** Insights list + "why?" evidence view; latest surfaced on dashboard.
- **Validation.** No insight below sample thresholds; every insight has confidence + disclaimer.
- **Errors.** Engine failure logs locally, never blocks the app; stale insights recomputed idempotently.
- **Future Evolution.** **Phase 1 rule engine** → **LLM explanations (opt-in)** → **on-device local AI** → **personalized AI**, plus conservative red-flag routing and richer correlations — following the [AI Evolution Roadmap](07-ai-rules.md#2b-ai-evolution-roadmap-phase-1--4).

## F12 — Reports
- **Purpose.** Daily/weekly/monthly/yearly views of nutrition, weight, habits, patterns.
- **Business rules.** Aggregation pushed into SQL with indexes; reports honor the **goal in force at the time** via `goal` versioning ([04](04-database-design.md) §4.2).
- **Data.** Read-only across all log tables.
- **UI/Nav.** Reports tab with range selector + charts ([05](05-uiux-system.md) §5.4); dataviz palette both themes.
- **Performance.** 1-year range ≤ 800 ms ([NFR-3](02-requirements.md)).
- **Errors.** Large ranges stream/paginate; empty ranges show guidance.
- **Future Evolution.** In-app charts → **PDF export** → **privacy-preserving shareable summaries** → **clinician-ready reports** ([15 Doctor Portal](15-release-roadmap.md)).

## F13 — Notifications
- **Purpose.** Gentle, local, opt-in reminders.
- **Business rules.** All local (`flutter_local_notifications`); **off by default** ([FR-34](02-requirements.md)); user-scheduled; no network.
- **Data.** Config in `app_meta`.
- **UI/Nav.** Settings → Reminders.
- **Validation.** Valid times; respects OS notification permission ([NFR-8](02-requirements.md)).
- **Errors.** `PermissionFailure` → explain + link to settings.
- **Future Evolution.** Fixed opt-in reminders → **anchored cues** (post-meal, [16](16-behavioral-design.md)) → **smart pattern-based nudges** (still local + opt-in, no dark patterns [knowledge/psychology/reward-system.md](../knowledge/psychology/reward-system.md)).

## F14 — Backup / Restore / Export / Import
- **Purpose.** Guarantee data ownership and durability ([FR-36](02-requirements.md)–39).
- **Business rules.** Encrypted backup (keystore key); version-headered; restore runs migrations if older; export = JSON/CSV; import validated + idempotent by UUID; wipe-all is hard delete with typed confirmation ([04](04-database-design.md) §8).
- **Data.** All tables; `app_meta.last_backup`.
- **UI/Nav.** Settings → Data.
- **Validation.** Header/schema checks; refuse newer-than-app backups.
- **Errors.** `BackupFailure(stage)` with clear recovery; all in transactions.
- **Future Evolution.** Manual encrypted backup → **scheduled auto-backup** → **optional E2E-encrypted cloud backup/sync** (opt-in, [13 §10](13-security-privacy.md), [15 Cloud](15-release-roadmap.md)).

## F15 — Settings & Privacy
- **Purpose.** Control theme, units, reminders, and privacy.
- **Business rules.** Theme (system/light/dark), units propagate everywhere; "works offline" affirmation; "delete all data"; disabled "Cloud sync (coming soon)" ([FR-42](02-requirements.md)).
- **Data.** `user_profile` (units), `app_meta`.
- **UI/Nav.** More → Settings.
- **Validation.** Enum-bound selections.
- **Errors.** standard.
- **Future Evolution.** Core settings → **Health Connect toggles** → **cloud-sync enablement** (opt-in) → **per-metric privacy controls** → **premium options** ([15](15-release-roadmap.md)).

---

## Future Features (interfaces/schema only in v1)
| Feature | Status | Hook |
|---|---|---|
| Medication tracking (FR-23) | Deferred | `medication*` tables sketched ([04](04-database-design.md) §4.9) |
| Cloud sync | Designed, not built | sync columns + UUIDs ([04](04-database-design.md) §10) |
| Health Connect | Roadmap | `health_connect_source` provenance table |
| Wear OS | Roadmap | presentation decoupled from logic ([05](05-uiux-system.md) §8) |
| Voice / image logging | Roadmap | `VoiceLogger`/`FoodImageRecognizer` interfaces ([07](07-ai-rules.md) §8) |
| Micronutrients | Roadmap | `food_item_nutrient` k/v table |

---

*Next: [Phase 9 — Folder Structure](09-folder-structure.md).*
