# Product Decision: Why AI Is Not a Doctor

- **Status:** Accepted
- **Date:** 2026-07-21
- **Companion ADR:** [ADR-0007](../docs/adr/0001-record-architecture-decisions.md#adr-0007--ai-is-on-device-rule-based-and-deterministic-in-v1) (technical: on-device, rule-based first).

## Context
An AI that analyzes health data is easily mistaken for — or tempted into becoming — a diagnostic tool.
That is a serious safety, ethical, and liability line. Health topics are also high-risk for AI
hallucination.

## Decision
LifeLedger's AI is a **Health Assistant, not a doctor.** It **never diagnoses disease, never
prescribes, and always states uncertainty.** It analyzes patterns in the user's *own* data and
suggests gentle, reversible experiments — nothing more. Every insight carries a confidence level and a
persistent "informational, not medical advice" disclaimer ([docs/07 §6](../docs/07-ai-rules.md)).

## Rationale
- **Safety:** a wrong diagnosis from an app can cause real harm; we design so diagnosis is *impossible
  by construction* (template-only generation + safety filter, [docs/07 §6](../docs/07-ai-rules.md)).
- **Honesty:** correlation is not causation; the app hedges and caps confidence
  ([knowledge/symptoms.md](../knowledge/symptoms.md), [docs/07 §5](../docs/07-ai-rules.md)).
- **Trust & scope:** we empower users to understand themselves and to have better conversations with
  *real* clinicians — we don't replace them.
- **Mission fit:** understanding, not verdicts ([docs/01](../docs/01-vision.md)).

## Consequences
- **Cost:** we deliberately hold back from "impressive" but unsafe diagnostic-sounding output; some
  users may want more definitive answers than we will ever give.
- **Benefit:** a safe, trustworthy, legally-defensible assistant; the red-flag path only ever suggests
  *"consider speaking with a healthcare professional."*

## Revisit if
Never for diagnosis. Any future clinical-adjacent capability (e.g., a **Doctor Portal**,
[docs/15](../docs/15-release-roadmap.md)) keeps the human clinician in charge — the app informs, the
clinician decides.

## Links
[docs/07 AI Rules](../docs/07-ai-rules.md) · [knowledge/symptoms.md](../knowledge/symptoms.md) · [why-health-score-exists.md](why-health-score-exists.md)
