# Architecture Decision Records (ADR Log)

> Part of the [LifeLedger Specification](../00-README-index.md).

This is an **append-only** journal of significant architectural decisions. Never rewrite a past
ADR; if a decision changes, add a new ADR that **supersedes** it and update the status of the old
one. This preserves the *why* for a team maintaining the project for a decade.

## How to add an ADR
Copy the template below, give it the next number, and fill it in. Keep it short — one decision each.

```
## ADR-000N — <Title>
- **Status:** Proposed | Accepted | Superseded by ADR-000M | Deprecated
- **Date:** YYYY-MM-DD
- **Context:** What forces/problem prompted this?
- **Decision:** What we chose.
- **Consequences:** Trade-offs, what becomes easier/harder.
- **Alternatives considered:** What we rejected and why.
```

---

## ADR-0001 — Record architecture decisions
- **Status:** Accepted
- **Date:** 2026-07-21
- **Context:** A 10-year-lived project needs a durable record of *why* decisions were made, not just *what* the code does.
- **Decision:** Maintain an append-only ADR log in `docs/adr/`. Every significant decision gets an ADR referenced from the relevant spec document.
- **Consequences:** Small overhead per decision; large payoff in maintainability and onboarding. Decisions become reviewable and reversible-with-context.
- **Alternatives considered:** Ad-hoc comments/commit messages (not discoverable); a wiki (drifts from the repo). Rejected in favor of in-repo, versioned ADRs.

## ADR-0002 — State management: BLoC + Cubit
- **Status:** Accepted
- **Date:** 2026-07-21
- **Context:** Enterprise Clean Architecture app needing testable, explicit state; team familiarity with BLoC/Cubit from prior Flutter work.
- **Decision:** Use `bloc`/`flutter_bloc` — Cubit for simple state, Bloc for event-driven flows. Full analysis in [03 §2](../03-architecture.md).
- **Consequences:** More boilerplate (mitigated by Cubit); in return, deterministic, unit-testable state and clean UI/logic separation.
- **Alternatives considered:** Riverpod (different idiom, DI/state blur), Provider (scales poorly), setState-only (untestable), GetX/MobX (concern-mixing / ecosystem fit). All rejected — see [03 §2.1](../03-architecture.md).

## ADR-0003 — Dependency injection: get_it + injectable
- **Status:** Accepted
- **Date:** 2026-07-21
- **Context:** Need DI decoupled from state management and from the domain layer.
- **Decision:** `get_it` service locator configured by `injectable` codegen; registration only at the composition root ([03 §3](../03-architecture.md)).
- **Consequences:** Clear separation of DI (get_it) from state (BLoC); domain stays framework-agnostic; easy test overrides.
- **Alternatives considered:** Riverpod-as-DI (couples DI to state), manual constructor wiring (verbose at scale). Rejected.

## ADR-0004 — Functional error handling with Either/Result
- **Status:** Accepted
- **Date:** 2026-07-21
- **Context:** Errors must be explicit and not leak exceptions across layers.
- **Decision:** Repositories/use cases return `Either<Failure, T>`; infrastructure maps low-level exceptions to a sealed `Failure` taxonomy ([03 §4](../03-architecture.md)).
- **Consequences:** Compile-time-visible error paths; no silent failures; slightly more verbose call sites.
- **Alternatives considered:** Throwing exceptions across layers (implicit, easy to miss). Rejected.

## ADR-0005 — Persistence: SQLite via sqflite + forward-only migrations
- **Status:** Accepted
- **Date:** 2026-07-21
- **Context:** Offline-first structured health data with integrity and a 10-year migration horizon.
- **Decision:** `sqflite` (+ `sqflite_common_ffi` for tests); hand-written, forward-only, immutable migrations keyed on `PRAGMA user_version`; FK enforcement on ([04 §7](../04-database-design.md)).
- **Consequences:** Full control and testability of schema evolution; more manual work than an ORM; every schema change requires a migration test.
- **Alternatives considered:** `drift` (great, but more magic/codegen; accepted as a future option), Hive/NoSQL (weak for relational time-series + integrity). Rejected for v1.

## ADR-0006 — Nutrition derived (not snapshotted) on food_entry in v1
- **Status:** Accepted (deferral)
- **Date:** 2026-07-21
- **Context:** Editing a `food_item` retroactively changes historical entry nutrition ([04 §9](../04-database-design.md)).
- **Decision:** v1 derives nutrition via join for simplicity and single-source-of-truth; accept the historical-accuracy risk, mitigated later by copy-on-write food versioning and/or snapshot columns.
- **Consequences:** Simpler v1 schema; a known, documented trade-off rather than an accidental one; a clear future migration path.
- **Alternatives considered:** Snapshot nutrition onto every entry now (more storage/complexity before it's needed). Deferred.

## ADR-0007 — AI is on-device, rule-based, and deterministic in v1
- **Status:** Accepted
- **Date:** 2026-07-21
- **Context:** "AI-Ready" must not break the offline + privacy promises; health topics are high-risk for hallucination.
- **Decision:** v1's insight engine is a deterministic, on-device, rule-based system with a mandatory safety filter and stable interfaces (`InsightEngine`, `FoodTextParser`) for future ML ([07](../07-ai-rules.md)).
- **Consequences:** Private, explainable, testable, zero-cost inference; less "smart" than an LLM until on-device models mature; any cloud option is future, opt-in, and never required.
- **Alternatives considered:** Cloud LLM (breaks privacy/offline; hallucination + cost). Rejected for the core; possible labeled opt-in accessory later.
