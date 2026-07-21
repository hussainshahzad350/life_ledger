# Phase 10 — Coding Standards

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [03](03-architecture.md), [09](09-folder-structure.md). Feeds: [11](11-testing-strategy.md), [12](12-implementation-plan.md).

Standards exist so a codebase maintained for 10 years reads as if written by one careful author.
These are **enforced** by linting, CI, and code review — not optional style preferences.

---

## 1. Language & Formatting

- **Dart**, formatted by `dart format` (no manual formatting debates). CI fails on unformatted code.
- **Linting:** `flutter_lints` as a base, extended with a stricter `analysis_options.yaml`
  (below). CI fails on any analyzer warning — **zero-warning policy**.
- **Null safety:** sound null safety everywhere; avoid `!` (bang) — prefer explicit handling.
- **Immutability by default:** models are immutable (`freezed`/`const` constructors, `final` fields).

### 1.1 `analysis_options.yaml` (intent)
```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore   # freezed
    # treat lints as build-breaking:
    todo: warning
linter:
  rules:
    - prefer_const_constructors
    - prefer_final_locals
    - avoid_print                 # use AppLogger, never print ([03] §5)
    - require_trailing_commas
    - always_declare_return_types
    - unawaited_futures
    - avoid_dynamic_calls
    - use_build_context_synchronously
```

---

## 2. Naming Conventions

| Kind | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `food_repository_impl.dart` |
| Classes / enums / typedefs | `UpperCamelCase` | `FoodEntry`, `MealSlot` |
| Members / variables / functions | `lowerCamelCase` | `logFoodEntry` |
| Constants | `lowerCamelCase` (or `SCREAMING` for well-known domain constants) | `paletteSeed`, `MSJ_WEIGHT` |
| Blocs/Cubits | `<Feature>Bloc` / `<Feature>Cubit` + `Event`/`State` | `FoodLogBloc` |
| Use cases | verb-first noun | `LogFoodEntry`, `GetDayTimeline` |
| Repository interface / impl | `XRepository` / `XRepositoryImpl` | `FoodRepository` |
| Test files | `<subject>_test.dart` | `health_score_test.dart` |

- **Booleans** read as predicates: `isDeleted`, `hasGoal`, `canSync`.
- **No abbreviations** except well-known ones (`id`, `db`, `dto`, `bmr`, `tdee`, `bmi`).

---

## 3. Documentation (mandatory)

- **Every public class, method, and top-level function has a `///` doc comment** ([NFR-22](02-requirements.md)).
- Doc comments state **what and why**, not restated code. Reference the spec where relevant
  (e.g., "Implements the Mifflin–St Jeor BMR, see docs/06 §2").
- **Health/AI constants** carry an inline source citation comment (the constant tables in
  [06](06-health-rules.md) §11 / [07](07-ai-rules.md) §4 are the canonical reference).
- Non-obvious decisions link to their ADR.

Example:
```dart
/// Computes Basal Metabolic Rate using the Mifflin–St Jeor equation.
///
/// See docs/06-health-rules.md §2. Constants live in [HealthConstants].
/// Returns kcal/day. For [Sex.unspecified] the averaged constant is used
/// and the result is flagged as a reduced-confidence estimate.
double basalMetabolicRate({ ... }) { ... }
```

---

## 4. Architecture Rules in Code (enforced)

1. **No layer leakage.** `domain/` must not import `package:flutter/*`, `sqflite`, or any feature's
   `infrastructure`/`presentation`. Enforced by an import-lint rule + review checklist ([03](03-architecture.md) §1.1).
2. **Repositories return `Either<Failure, T>`** — never throw across boundaries ([03](03-architecture.md) §4).
3. **No business logic in widgets.** Widgets render state and dispatch events only ([03](03-architecture.md) §2).
4. **No `DateTime.now()` / `print` in domain/app.** Use `Clock` and `AppLogger` ([03](03-architecture.md) §5).
5. **No magic numbers.** Product-meaningful numbers are named constants in the documented constant
   files ([09](09-folder-structure.md)). A raw literal in a formula fails review.
6. **DI only at the composition root.** Features never `new` a concrete repository ([03](03-architecture.md) §3).

---

## 5. Error Handling & Logging

- Map every caught low-level exception to a typed `Failure` at the infrastructure boundary.
- Never swallow errors silently; either surface to the user or log via `AppLogger` (local only).
- User-facing messages are localized and actionable — never a stack trace ([05](05-uiux-system.md) §6).
- `AppLogger` writes **no PII** and **never** to the network ([NFR-5](02-requirements.md)/9).

---

## 6. Asynchrony & State

- `await` all futures or explicitly mark `unawaited(...)`; the `unawaited_futures` lint is on.
- Guard `BuildContext` across async gaps (`use_build_context_synchronously`).
- State classes are exhaustive unions; UI handles every case (no default fall-through that hides a state).
- Heavy work off the UI isolate where measured to matter ([03](03-architecture.md) §5).

---

## 7. Dependency Policy (privacy gate)

A new package is added only if it:
1. Contains **no** ads and **no** analytics/telemetry ([NFR-5](02-requirements.md)).
2. Is actively maintained and license-compatible (permissive; document the license).
3. Earns its weight (no trivial one-liner deps).
4. Is pinned to a specific version range and reviewed on upgrade.

Every dependency addition is noted in the PR description with its justification and license.

---

## 8. Git & Review Workflow

- **Branching:** feature branches off `main`; small, focused PRs.
- **Commits:** imperative mood, scoped, explain *why*. Suggested convention:
  `feat(food_logging): add quick-add recents grid`. Reference spec sections/ADRs where relevant.
- **PRs:** must state which requirement(s)/feature(s) they implement, include tests, and pass CI
  (format + analyze + test + coverage gate). Draft PRs for work in progress.
- **Review checklist** (blocking): layer boundaries respected; public APIs documented; no magic
  numbers; tests added; accessibility considered for UI; no new network/analytics.

---

## 9. Testing Expectations (summary; full detail in [11](11-testing-strategy.md))

- Every use case, repository, and engine function has unit tests.
- Every Bloc/Cubit has `bloc_test` coverage.
- Every migration has a data-preservation test.
- Coverage gate enforced in CI (targets in [11](11-testing-strategy.md)).

---

## 10. Performance & Accessibility as Standards

- Performance budgets ([NFR-1](02-requirements.md)–4) are acceptance criteria, not aspirations;
  regressions block merge where measurable.
- Accessibility ([05](05-uiux-system.md) §7) is part of Definition of Done for any UI PR: semantic
  labels, 48 dp targets, text scaling, contrast.

---

*Next: [Phase 11 — Testing Strategy](11-testing-strategy.md).*
