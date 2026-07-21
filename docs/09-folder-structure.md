# Phase 9 — Folder Structure

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [03](03-architecture.md). Feeds: [10](10-coding-standards.md), [12](12-implementation-plan.md).

The project is **feature-first**: each feature owns its full Clean Architecture slice, and anything
shared by ≥ 2 features is promoted to `core/`. This mirrors the layer rules in
[03](03-architecture.md) and makes features independently understandable and testable.

---

## 1. Top-Level Layout

```
life_ledger/
├─ android/                      # Android host (min SDK 24, target latest)
├─ assets/
│  ├─ food_db/                   # bundled seed food dataset (offline)
│  └─ fonts/                     # licensed fonts
├─ lib/
│  ├─ main.dart                  # entrypoint: bootstrap + runApp
│  ├─ app/                       # app shell: MaterialApp, router, theme wiring
│  ├─ core/                      # shared, cross-feature building blocks
│  └─ features/                  # one folder per feature (F1..F15)
├─ test/                         # mirrors lib/ (unit + widget)
├─ integration_test/             # end-to-end flows on device/emulator
├─ docs/                         # THIS specification set
└─ pubspec.yaml                  # (created at implementation time)
```

> Note: `pubspec.yaml`, `lib/`, and `android/` do **not** exist yet — this is the target layout the
> implementation phase will create. This document is the blueprint, not the current tree.

---

## 2. `core/` — shared infrastructure & primitives

```
lib/core/
├─ error/
│  ├─ failure.dart               # sealed Failure taxonomy ([03] §4)
│  └─ result.dart                # Either/Result helpers
├─ database/
│  ├─ app_database.dart          # sqflite open/config (FK ON), version constant
│  ├─ migrations/                # forward-only migrations, one file per version
│  │  ├─ migration.dart          # Migration interface
│  │  └─ v1_initial.dart         # DDL for schema v1 ([04])
│  └─ dao/                       # shared DAO helpers (audit/sync columns)
├─ di/
│  └─ injector.dart              # get_it + injectable composition root ([03] §3)
├─ time/
│  └─ clock.dart                 # Clock abstraction (no direct DateTime.now)
├─ health/                       # PURE health engine ([06]) — domain-level, no Flutter
│  ├─ constants.dart             # every named constant from [06] §11 (single source)
│  ├─ bmr_tdee.dart
│  ├─ goals.dart                 # calorie/protein/macro/water goal calculators
│  ├─ bmi.dart
│  └─ health_score.dart
├─ ai/                           # PURE insight engine ([07]) — interfaces + rules
│  ├─ insight_engine.dart        # InsightEngine interface + rule runner
│  ├─ rules/                     # one pure function per rule_id ([07] §3)
│  ├─ correlation.dart           # simple, explainable stats ([07] §5)
│  ├─ safety_filter.dart         # mandatory output gate ([07] §6)
│  └─ food_text_parser.dart      # FoodTextParser interface + v1 deterministic impl
├─ theme/
│  ├─ app_theme.dart             # M3 ColorScheme, light/dark ([05])
│  └─ tokens.dart                # spacing/radius/type tokens — no magic styling
├─ localization/                 # generated AppLocalizations + .arb ([02] NFR-24)
├─ widgets/                      # shared, dumb widgets (metric ring, empty state)
├─ utils/                        # units conversion, formatters (locale-aware)
└─ constants/                    # app-wide non-health constants (enum codes, keys)
```

**Rationale:** the health and AI engines live in `core/` because they are pure, cross-feature, and
must be unit-testable in isolation ([06](06-health-rules.md)/[07](07-ai-rules.md) both require this).
Keeping them Flutter-free protects testability and portability.

---

## 3. A Feature Slice (canonical shape)

Every feature under `lib/features/<feature>/` follows the same four-layer internal structure.
Example: **food logging** (F3).

```
lib/features/food_logging/
├─ domain/                       # pure Dart — no Flutter, no sqflite
│  ├─ entities/
│  │  ├─ food_item.dart
│  │  └─ food_entry.dart
│  ├─ value_objects/
│  │  ├─ quantity.dart           # validates > 0 ([08] F3)
│  │  └─ meal_slot.dart          # enum + parsing
│  └─ repositories/
│     └─ food_repository.dart    # INTERFACE returning Either<Failure, T> ([03] §4)
├─ application/                  # use cases (one operation each)
│  ├─ log_food_entry.dart
│  ├─ edit_food_entry.dart
│  ├─ delete_food_entry.dart     # soft delete + Undo
│  ├─ search_food.dart
│  └─ get_day_timeline.dart
├─ infrastructure/               # implements domain interfaces
│  ├─ datasources/
│  │  └─ food_local_datasource.dart   # sqflite queries ([04] indexes)
│  ├─ dtos/
│  │  └─ food_entry_dto.dart     # row <-> entity mapping
│  └─ repositories/
│     └─ food_repository_impl.dart
└─ presentation/                 # Flutter + BLoC/Cubit only
   ├─ bloc/
   │  ├─ food_log_bloc.dart      # events/states ([03] §2)
   │  ├─ food_log_event.dart
   │  └─ food_log_state.dart
   ├─ pages/
   │  ├─ quick_add_page.dart
   │  └─ journal_page.dart
   └─ widgets/
      ├─ recents_grid.dart
      └─ meal_group.dart
```

**Dependency direction inside a feature:** `presentation → application → domain`, and
`infrastructure → domain` (implements interfaces). `presentation` never imports `infrastructure`
or `sqflite` — wiring happens only in the DI composition root ([03](03-architecture.md) §3).

---

## 4. Feature Inventory (maps to [08](08-feature-specs.md))

```
lib/features/
├─ onboarding/         # F1/F2 onboarding wizard
├─ profile/            # F1 profile
├─ goals/              # F2 goals (versioned)
├─ food_logging/       # F3 (canonical slice above)
├─ water/              # F4
├─ weight/             # F5
├─ sleep/              # F6
├─ mood/               # F7
├─ symptoms/           # F8
├─ exercise/           # F9
├─ dashboard/          # F10 (reads across features via domain contracts)
├─ insights/           # F11 (uses core/ai)
├─ reports/            # F12
├─ notifications/      # F13
├─ data_management/    # F14 backup/restore/export/import
└─ settings/           # F15
```

> Cross-feature reads (e.g., the dashboard aggregating water + food + weight) go through **domain
> repository interfaces** of those features or a dedicated `dashboard` read-model — never through
> another feature's infrastructure ([03](03-architecture.md) §7).

---

## 5. Test Layout (mirrors `lib/`)

```
test/
├─ core/
│  ├─ health/            # engine unit tests vs. [06] worked examples
│  ├─ ai/                # rule + safety + determinism tests ([07] §10)
│  └─ database/
│     └─ migrations/     # migration tests: v(N-1) → vN preserves data ([04] §7)
├─ features/<feature>/
│  ├─ domain/            # value-object validation
│  ├─ application/       # use-case tests (mocked repos)
│  ├─ infrastructure/    # DAO/repo tests on in-memory sqflite_common_ffi
│  └─ presentation/      # bloc_test + widget tests
integration_test/
└─ flows/                # < 10 s food log, backup/restore round-trip, offline run
```

Details and coverage targets in [`11-testing-strategy.md`](11-testing-strategy.md).

---

## 6. Naming & Placement Rules

| Rule | Rationale |
|---|---|
| One public class per file, `snake_case.dart` named after it. | Predictable navigation. |
| Interfaces in `domain/repositories`; impls in `infrastructure/repositories`. | Enforces the boundary. |
| No `sqflite`/`flutter` import under any `domain/`. | Purity = testability ([03] §1.1). |
| Shared-by-≥2-features code → `core/`; single-feature code stays local. | Prevents premature abstraction and God utils. |
| Blocs/Cubits only under `presentation/bloc`. | State lives in one predictable place. |
| Every constant with product meaning → a named file (`core/health/constants.dart`, `core/constants/`). | No magic numbers ([06]/[07]). |

---

*Next: [Phase 10 — Coding Standards](10-coding-standards.md).*
