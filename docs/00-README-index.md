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
| 13 | [Security & Privacy](13-security-privacy.md) | — | Threat model, encryption, permissions, data retention, cloud-security design | 02, 03, 04 |
| 14 | [Performance](14-performance.md) | — | Concrete budgets, DB/query/render/memory/battery, offline targets | 02, 03, 04 |
| 15 | [Release Roadmap](15-release-roadmap.md) | — | Product ladder: MVP → v1.0 → v1.1 → Premium → AI → Cloud → Wear OS → Doctor → Family | 12 |
| 16 | [Behavioral Design](16-behavioral-design.md) | — | Applies behavioral science to UX ("optimize for behavior") | 05, KB/psychology |
| 17 | [Food Database](17-food-database.md) | — | Food catalog: nutrients, units, servings, aliases, localized/restaurant/recipes/brands | 04 |
| 18 | [Health Decision Engine](18-health-decision-engine.md) | — | Evaluation layer (formulas → decisions) + Decision Log | 06, 04 |
| — | [ADR Log](adr/0001-record-architecture-decisions.md) | — | Architecture Decision Records (append-only technical decisions) | — |

### Knowledge & Decisions (Single Source of Truth)
Beyond the numbered specs, three top-level folders hold the durable knowledge foundation that powers
the AI, insights, in-app Help/Education, and the future chat assistant:

| Folder | Purpose |
|---|---|
| [`/knowledge`](../knowledge/00-index.md) | Health Knowledge Base — one file per topic (protein, water, sleep…), evidence-tagged; plus [`/knowledge/psychology`](../knowledge/psychology/00-index.md) (behavioral science). **The single source of truth for health facts.** |
| [`/research`](../research/00-index.md) | Source Registry — WHO, NIH, Dietary Guidelines, USDA, Pakistan data, research papers. The citation backbone. |
| [`/decisions`](../decisions/00-index.md) | **Product** decisions (why offline-first, why no ads, why AI isn't a doctor…), distinct from the technical ADR log. |

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
| **ADR** | Architecture Decision Record — an append-only note capturing one significant *technical* decision. |
| **Product Decision** | A *product/ethics* "why" record in [`/decisions`](../decisions/00-index.md), distinct from an ADR. |
| **Knowledge Base (KB)** | [`/knowledge`](../knowledge/00-index.md) — the single source of truth for health facts, referenced (not restated) by rules/AI/Help. |
| **Evidence Level** | A–D strength tag on a knowledge claim; governs how confidently the AI may state it. |
| **Decision Engine** | The evaluation layer ([18](18-health-decision-engine.md)) that turns computed values into decisions + a Decision Log. |

---

## 6. How to Extend This Documentation

- **New significant *technical* decision?** Add an ADR under [`adr/`](adr/) (copy the template in ADR-0001). A **product** decision goes in [`/decisions`](../decisions/00-index.md). Do not silently rewrite history.
- **New feature?** Add it to [`08-feature-specs.md`](08-feature-specs.md), then cascade changes into DB ([04](04-database-design.md)), UI ([05](05-uiux-system.md)), rules ([06](06-health-rules.md)/[07](07-ai-rules.md)) as needed.
- **New health fact?** Add/extend a [`/knowledge`](../knowledge/00-index.md) file (evidence-tagged, sourced via [`/research`](../research/00-index.md)); link it from the rule/AI that uses it. One fact, one home.
- **Schema change?** Bump the DB version and add a migration in [04](04-database-design.md). Never edit an existing migration.
- **Consistency rule:** every feature traces to a table, a screen, and (where relevant) a health/AI rule and a knowledge file. Orphans are bugs.

---

## 7. Changelog

| Date | Version | Change |
|---|---|---|
| 2026-07-21 | 0.1.0 | Initial complete 12-phase specification set authored (documentation-only). |
| 2026-07-21 | 0.2.0 | Knowledge & decision foundation: added `/knowledge` (13 health + 8 psychology), `/research` registry, `/decisions` (5 product decisions); new docs 13–18 (Security & Privacy, Performance, Release Roadmap, Behavioral Design, Food Database, Health Decision Engine); enriched 06 (per-rule template), 07 (AI evolution roadmap + full rule template), 08 (Future Evolution per feature). |

---

*Maintainers: treat this index as the entry point for every new team member. If a document
and this index disagree, fix both in the same change.*
