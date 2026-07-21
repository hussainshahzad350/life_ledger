# LifeLedger

> **Understand your body, one day at a time.**

LifeLedger is an **Offline-First, Privacy-First, AI-Ready Personal Health Journal** for Android
(Flutter). It helps people understand their body through long-term health *patterns* — not by
counting calories. It is a Personal Health Operating System, not a diet app or a fitness tracker.

It aims to answer the questions people actually ask about their bodies — *Why am I always hungry?
Am I eating enough protein? Which foods make me feel worse? Am I drinking enough water?* — by
discovering answers in the user's **own** data.

## Status

📋 **Specification phase.** This repository currently contains the **complete software
specification** and documentation roadmap. **No production code exists yet — by design.**
Implementation begins only after the specification is reviewed and accepted.

## Principles

- **Offline-first** — fully functional with the network permanently off.
- **Privacy-first** — no ads, no analytics, no data selling. The user owns their data.
- **Simple** — logging breakfast takes under 10 seconds.
- **Accurate** — no magic numbers; every health formula is documented and sourced.
- **Not medical advice** — LifeLedger informs; it never diagnoses or replaces a clinician.

## Documentation

Start at the specification index:

### 👉 [`docs/00-README-index.md`](docs/00-README-index.md)

The spec is organized in 12 phases (Vision → Requirements → Architecture → Database → UI/UX →
Health Rules → AI Rules → Feature Specs → Folder Structure → Coding Standards → Testing →
Implementation Plan), plus an append-only [Architecture Decision Record log](docs/adr/0001-record-architecture-decisions.md).

## Tech (decided in the spec)

Flutter (Material 3, Android-first) · Clean Architecture · **BLoC + Cubit** · `get_it`/`injectable`
DI · **SQLite** (`sqflite`) with forward-only migrations · deterministic on-device rule-based
health & insight engines. Rationale for each is in the [Architecture doc](docs/03-architecture.md)
and the [ADR log](docs/adr/0001-record-architecture-decisions.md).
