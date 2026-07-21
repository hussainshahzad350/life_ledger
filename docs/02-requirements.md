# Phase 2 — Requirements

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [01](01-vision.md). Feeds: [03](03-architecture.md)–[12](12-implementation-plan.md).

This document defines **what** the system must do (functional) and **how well** (non-functional).
Requirements are identified (`FR-x`, `NFR-x`) so later documents can trace to them. Priorities
use **MoSCoW**: **M**ust / **S**hould / **C**ould / **W**on't-yet.

---

## 1. Scope of v1 (MVP → v1.0)

**In scope:** local profile, goals, daily journal, food/water/weight/sleep/mood/symptom/exercise
logging, dashboard, reports, rule-based insights, notifications, settings, backup/restore,
export/import.

**Designed but not implemented in v1:** cloud sync, Health Connect, Wear OS, medication tracking,
on-device ML, voice logging, image recognition. These have interfaces and schema hooks but no
implementation (see [08](08-feature-specs.md) §Future and [12](12-implementation-plan.md)).

---

## 2. Functional Requirements

### 2.1 Onboarding & Profile
| ID | Requirement | Priority |
|---|---|---|
| FR-1 | User can create a local profile (name optional, sex, birth date, height) with no account or network. | M |
| FR-2 | User can set units (metric/imperial) and the app respects them everywhere. | M |
| FR-3 | User can edit profile at any time; dependent calculations recompute. | M |
| FR-4 | Profile creation is skippable with sensible defaults; the app is usable immediately. | S |

### 2.2 Goals
| ID | Requirement | Priority |
|---|---|---|
| FR-5 | App proposes default goals (calories, protein, water, weight) from profile via the health engine ([06](06-health-rules.md)). | M |
| FR-6 | User can override any goal manually; overrides persist and are labeled as user-set. | M |
| FR-7 | User can choose a weight objective (maintain / lose / gain) that adjusts calorie targets. | M |
| FR-8 | Goal changes are versioned (history retained) so reports reflect the goal in force at the time. | S |

### 2.3 Food & Meal Logging (core)
| ID | Requirement | Priority |
|---|---|---|
| FR-9 | User can log a food entry with quantity and meal slot (breakfast/lunch/dinner/snack). | M |
| FR-10 | Logging breakfast (cold app) completes in **< 10 s** (quick-add, recents, favorites). | M |
| FR-11 | Each food carries per-serving nutrition: calories, protein, carbs, fat, fiber, sugar. | M |
| FR-12 | User can create custom foods and mark favorites. | M |
| FR-13 | User can edit or (soft-)delete any logged entry; totals recompute. | M |
| FR-14 | A bundled offline food database seeds common foods (no network required). | M |
| FR-15 | Natural-language quick entry ("2 eggs and toast") is parsed into entries. | C |
| FR-16 | Meal timeline shows the day's food entries in chronological, grouped order. | M |

### 2.4 Other Trackers
| ID | Requirement | Priority |
|---|---|---|
| FR-17 | Log **water** intake with one tap (increment by a configurable unit). | M |
| FR-18 | Log **weight** with date; trend computed and charted. | M |
| FR-19 | Log **sleep** (duration and/or bed/wake times, optional quality). | M |
| FR-20 | Log **mood** on a simple ordinal scale with optional note. | M |
| FR-21 | Log **symptoms** (typed, severity, optional note) for correlation. | M |
| FR-22 | Log **exercise** (type, duration, optional intensity/energy). | S |
| FR-23 | Log **medication** (name, dose, schedule). | W (future) |

### 2.5 Dashboard
| ID | Requirement | Priority |
|---|---|---|
| FR-24 | Dashboard shows today's calories (consumed/remaining), protein, water, weight trend, health score — above the fold. | M |
| FR-25 | Dashboard offers one-tap access to the most common logging actions. | M |
| FR-26 | Dashboard surfaces the latest insight when one is available. | S |

### 2.6 Insights (AI as Health Assistant)
| ID | Requirement | Priority |
|---|---|---|
| FR-27 | The engine generates plain-language insights from the user's data (trends, streaks, correlations). | M |
| FR-28 | Every insight states its **confidence/uncertainty** and never diagnoses disease. | M |
| FR-29 | Insights are explainable: the user can see *why* an insight was produced (the underlying data). | S |
| FR-30 | User can dismiss or mark an insight helpful/unhelpful (feedback stored locally). | C |

### 2.7 Reports
| ID | Requirement | Priority |
|---|---|---|
| FR-31 | Daily, weekly, monthly, yearly reports for nutrition, weight, and habits. | M |
| FR-32 | Charts for calories, macros, water, weight, sleep, mood over selectable ranges. | M |
| FR-33 | Pattern reports correlate two series (e.g., food ↔ symptom, sleep ↔ mood). | S |

### 2.8 Notifications
| ID | Requirement | Priority |
|---|---|---|
| FR-34 | Local reminders (log meal, drink water, log weight) — user-configurable, off by default. | S |
| FR-35 | A daily insight/summary notification, opt-in. | C |

### 2.9 Data Ownership
| ID | Requirement | Priority |
|---|---|---|
| FR-36 | Full local **backup** (encrypted) and **restore**. | M |
| FR-37 | Export all data to a portable format (JSON and/or CSV). | M |
| FR-38 | Import previously exported data. | S |
| FR-39 | "Delete all my data" wipes local storage irreversibly (with confirmation). | M |

### 2.10 Settings
| ID | Requirement | Priority |
|---|---|---|
| FR-40 | Theme (system/light/dark), units, reminder config, and privacy controls. | M |
| FR-41 | App works with all network permissions denied. | M |
| FR-42 | Optional cloud sync toggle (present but disabled/"coming soon" in v1). | C |

---

## 3. Non-Functional Requirements

### 3.1 Performance
| ID | Requirement | Target |
|---|---|---|
| NFR-1 | Dashboard cold start | ≤ 1.5 s on a mid-range device (e.g., Snapdragon 6-series, 4 GB RAM). |
| NFR-2 | Log-entry save-to-reflected-on-dashboard | ≤ 200 ms perceived. |
| NFR-3 | Report render for a 1-year range | ≤ 800 ms. |
| NFR-4 | Frame budget | 60 fps; no jank on scroll/timeline. |

### 3.2 Privacy & Security
| ID | Requirement |
|---|---|
| NFR-5 | No advertising SDKs, no third-party analytics, no silent telemetry. |
| NFR-6 | No data leaves the device without explicit, revocable user consent. |
| NFR-7 | Backups are encrypted at rest; encryption keys never leave the device unencrypted. |
| NFR-8 | The app requests the **minimum** Android permissions; each is justified in [08](08-feature-specs.md). |
| NFR-9 | No network calls in the core flows; any future network feature is opt-in and clearly labeled. |

### 3.3 Reliability & Data Integrity
| ID | Requirement |
|---|---|
| NFR-10 | Crash-free session rate ≥ 99.5%. |
| NFR-11 | No data loss across app updates; every schema change ships a tested migration ([04](04-database-design.md)). |
| NFR-12 | Database enforces referential integrity (foreign keys ON) and domain constraints (CHECKs). |
| NFR-13 | All writes are transactional; partial writes never corrupt totals. |

### 3.4 Usability & Accessibility
| ID | Requirement |
|---|---|
| NFR-14 | Full light & dark themes (Material 3), including dynamic color where available. |
| NFR-15 | WCAG 2.1 AA contrast; supports large text/system font scaling without layout breakage. |
| NFR-16 | Screen-reader (TalkBack) labels on all interactive elements. |
| NFR-17 | Core flows reachable within 2 taps from the dashboard. |
| NFR-18 | Minimal typing; prefer taps, steppers, recents, and favorites. |

### 3.5 Maintainability & Portability
| ID | Requirement |
|---|---|
| NFR-19 | Clean Architecture with enforced layer boundaries ([03](03-architecture.md)). |
| NFR-20 | Business logic is 100% unit-testable without a device or UI. |
| NFR-21 | Every repository has an interface; every service has unit tests ([11](11-testing-strategy.md)). |
| NFR-22 | Every public class/method has documentation comments ([10](10-coding-standards.md)). |
| NFR-23 | Codebase is Android-first but avoids gratuitous platform lock-in (iOS-portable where free). |

### 3.6 Internationalization & Localization
| ID | Requirement |
|---|---|
| NFR-24 | All user-facing strings are externalized (`.arb`) for future localization; en-US is the base. |
| NFR-25 | Units, dates, and numbers respect locale/user preference. |

---

## 4. Constraints & Assumptions

- **Platform:** Flutter latest stable, Android min SDK **24 (Android 7.0)**, target latest stable SDK.
  *Rationale:* API 24 covers ~the vast majority of active devices while enabling modern APIs. (Assumption — revisit against current Play distribution data at implementation time.)
- **Single device, single user** per install in v1 (multi-profile is a future extension).
- **No backend** in v1. Cloud sync is designed-for but out of scope (see [04](04-database-design.md) §Sync-Readiness).
- **Nutrition data** for the seed food DB comes from an openly-licensed source (e.g., a public
  food-composition dataset); licensing to be confirmed before bundling (tracked in [12](12-implementation-plan.md)).

---

## 5. Acceptance Criteria (v1 Definition of Done, high level)

v1 is "done" when:

1. All **M**-priority FRs are implemented, tested, and traceable to code.
2. All NFRs are met or have a documented, accepted exception.
3. Every feature in [08](08-feature-specs.md) maps to a table ([04](04-database-design.md)), a screen ([05](05-uiux-system.md)), and (where relevant) a rule ([06](06-health-rules.md)/[07](07-ai-rules.md)).
4. Test coverage meets the targets in [11](11-testing-strategy.md).
5. The app runs fully offline with all network permissions denied.

---

*Next: [Phase 3 — Architecture](03-architecture.md).*
