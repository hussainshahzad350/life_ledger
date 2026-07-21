# LifeLedger — Software Specification & Documentation Roadmap

> **Understand your body, one day at a time.**

This directory is the **single source of truth** for the LifeLedger project. It is a
documentation-first specification produced *before* any production code, and it is
intended to be maintained by a professional software team for the next decade.

**Status of this pass:** Specification complete. **No production code exists yet by design.**
Implementation begins only after this specification is reviewed and accepted (see
[`12-implementation-plan.md`](12-implementation-plan.md)).

---

## 1. What LifeLedger Is (and Is Not)

LifeLedger is an **Offline-First, Privacy-First, AI-Ready Personal Health Journal** for
Android, built in Flutter. It helps users understand their body through long-term health
patterns rather than short-term calorie counting.

| It IS | It is NOT |
|---|---|
| A Personal Health Operating System | A calorie counter |
| A long-term pattern-discovery journal | A diet app |
| An offline-first, user-owned data vault | A fitness/step tracker |
| A privacy-preserving health assistant | A medical or diagnostic device |

The full articulation lives in [`01-vision.md`](01-vision.md).

---

## 2. Document Map & Reading Order

Read in numeric order. Each document assumes the ones before it. Later documents cite
earlier ones; the dependency direction is strictly downward.

| # | Document | Phase | Purpose | Depends on |
|---|---|---|---|---|
| 00 | **This file** | — | Roadmap, index, glossary, changelog | — |
| 01 | [Vision](01-vision.md) | 1 | Mission, non-goals, philosophy, personas, success metrics | — |
| 02 | [Requirements](02-requirements.md) | 2 | Functional + non-functional requirements, MoSCoW, user stories | 01 |
| 03 | [Architecture](03-architecture.md) | 3 | Clean Architecture, layers, DI, state management decision, error model | 01, 02 |
| 04 | [Database Design](04-database-design.md) | 4 | Schema, ERD, indexes, constraints, migrations, backup, sync-readiness | 02, 03 |
| 05 | [UI/UX System](05-uiux-system.md) | 5 | Material 3 design system, theming, navigation, accessibility, wireframes | 02, 03 |
| 06 | [Health Rules](06-health-rules.md) | 6 | Rule-based health engine — every formula, source, and assumption | 02, 04 |
| 07 | [AI Rules](07-ai-rules.md) | 7 | AI health-assistant design, insight rules, safety guardrails, roadmap | 04, 06 |
| 08 | [Feature Specifications](08-feature-specs.md) | 8 | Per-feature specs (purpose, rules, DB impact, UI, validation, errors) | 03–07 |
| 09 | [Folder Structure](09-folder-structure.md) | 9 | Feature-first Clean Architecture directory tree + layer responsibilities | 03 |
| 10 | [Coding Standards](10-coding-standards.md) | 10 | Dart/Flutter style, naming, docs, lint, immutability, commits | 03, 09 |
| 11 | [Testing Strategy](11-testing-strategy.md) | 11 | Test pyramid, coverage targets, DB harness, CI expectations | 03, 04, 10 |
| 12 | [Implementation Plan](12-implementation-plan.md) | 12 | Milestones, dependency-ordered work breakdown, Definition of Done | all |
| — | [ADR Log](adr/0001-record-architecture-decisions.md) | — | Architecture Decision Records (append-only decision journal) | — |

---

## 3. Non-Negotiable Product Principles

These constrain **every** decision in every document. If a proposed feature or design
violates one, it is rejected.

1. **Offline-First** — the app is fully functional with the network permanently off.
2. **Privacy-First** — no ads, no analytics SDKs, no data selling. The user owns their data.
3. **Simplicity** — adding breakfast takes **< 10 seconds**. Every feature must justify its existence.
4. **Accuracy** — no magic numbers. Every health calculation is documented and sourced.
5. **Performance** — a dashboard cold-start budget of **≤ 1.5 s** on a mid-range device.
6. **Maintainability & Scalability** — Clean Architecture, modular, testable, no God classes.
7. **Not Medical Advice** — LifeLedger informs; it never diagnoses or replaces a clinician.

---

## 4. Key Decisions at a Glance

These are decided here and justified in the referenced documents. Changes require a new ADR.

| Area | Decision | Where justified |
|---|---|---|
| Platform | Flutter (latest stable), Android-first, Material 3 | [03](03-architecture.md) |
| Architecture | Clean Architecture, 4 layers, feature-first | [03](03-architecture.md) |
| State management | **BLoC + Cubit** (Riverpod/Provider evaluated & rejected) | [03](03-architecture.md) |
| Dependency injection | `get_it` + `injectable` | [03](03-architecture.md) |
| Persistence | **SQLite** via `sqflite` (+ `sqflite_common_ffi` for tests) | [03](03-architecture.md), [04](04-database-design.md) |
| Migrations | Hand-written, `PRAGMA user_version`, forward-only | [04](04-database-design.md) |
| Health engine | Deterministic, rule-based, sourced formulas | [06](06-health-rules.md) |
| AI engine (v1) | Deterministic rule-based insight engine (no cloud LLM) | [07](07-ai-rules.md) |
| Cloud sync | Designed-for, **not implemented in v1** (interface only) | [04](04-database-design.md), [08](08-feature-specs.md) |
| Error model | `Either<Failure, T>` (functional error handling, no exceptions across layers) | [03](03-architecture.md) |

---

## 5. Glossary

| Term | Definition |
|---|---|
| **Entry / Log** | A single timestamped health record (food, water, weight, mood, etc.). |
| **Journal** | The chronological collection of a user's entries for a day. |
| **Meal Timeline** | The ordered view of food entries within a day (breakfast → snacks → dinner). |
| **Health Score** | A composite 0–100 daily indicator derived from goal adherence. See [06](06-health-rules.md). |
| **Insight** | A plain-language observation generated by the AI engine from patterns in data. See [07](07-ai-rules.md). |
| **BMR** | Basal Metabolic Rate — calories at complete rest. |
| **TDEE** | Total Daily Energy Expenditure — BMR × activity factor. |
| **Macro** | Macronutrient: protein, carbohydrate, or fat. |
| **AI (in LifeLedger)** | A *health assistant* that analyzes patterns — **not** a chatbot and **not** a diagnostician. |
| **Use Case** | A single application-layer operation (one verb) orchestrating domain + repositories. |
| **Failure** | A typed, domain-level error object returned via `Either`, never thrown across layers. |
| **Soft delete** | Marking a row deleted (`is_deleted = 1`) rather than removing it — preserves sync history. |
| **ADR** | Architecture Decision Record — an append-only note capturing one significant decision. |

---

## 6. How to Extend This Documentation

- **New significant decision?** Add an ADR under [`adr/`](adr/) (copy the template in ADR-0001). Do not silently rewrite history.
- **New feature?** Add it to [`08-feature-specs.md`](08-feature-specs.md), then cascade changes into DB ([04](04-database-design.md)), UI ([05](05-uiux-system.md)), rules ([06](06-health-rules.md)/[07](07-ai-rules.md)) as needed.
- **Schema change?** Bump the DB version and add a migration in [04](04-database-design.md). Never edit an existing migration.
- **Consistency rule:** every feature must trace to a table, a screen, and (where relevant) a health/AI rule. Orphans are bugs.

---

## 7. Changelog

| Date | Version | Change |
|---|---|---|
| 2026-07-21 | 0.1.0 | Initial complete 12-phase specification set authored (documentation-only). |

---

*Maintainers: treat this index as the entry point for every new team member. If a document
and this index disagree, fix both in the same change.*
