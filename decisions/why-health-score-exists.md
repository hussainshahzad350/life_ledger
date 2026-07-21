# Product Decision: Why the Health Score Exists

- **Status:** Accepted
- **Date:** 2026-07-21

## Context
A single "score" is powerful for motivation and at-a-glance clarity — and dangerous if misread as a
medical verdict on someone's health. We must have the motivational benefit **without** the false-verdict
risk.

## Decision
LifeLedger includes a **Health Score (0–100)** defined **narrowly and explicitly** as a **daily
goal-adherence indicator** — "how close was I to *my own* goals today?" — **not** a judgment of health.
Its formula, weights, and caps are documented and **user-tunable** ([docs/06 §9](../docs/06-health-rules.md)).

## Rationale
- **Behavioral value:** a clear daily number gives immediate feedback and a reward signal that
  reinforces logging ([knowledge/psychology/reward-system.md](../knowledge/psychology/reward-system.md)),
  and answers the dashboard's "health score?" question ([docs/01 §6](../docs/01-vision.md)).
- **Honesty & safety:** by defining it as *goal adherence* (with a visible label and disclaimer), we
  avoid implying a medical assessment — consistent with
  [why-ai-is-not-a-doctor.md](why-ai-is-not-a-doctor.md).
- **Transparency:** no black box — every component and weight is documented and adjustable, so the user
  can see exactly why the number is what it is.

## Consequences
- **Cost:** we must relentlessly guard the framing (UI copy, docs) so it's never read as "you are
  X% healthy"; over-shooting targets is capped so the number can't be gamed.
- **Benefit:** motivation and glanceability with integrity; a score that rewards the user's *own*
  chosen goals, not a one-size verdict.

## Revisit if
User testing shows the score is consistently misread as medical judgment despite framing — in which
case we adjust presentation (or the name) rather than abandon the goal-adherence signal.

## Links
[docs/06 §9 Health Score](../docs/06-health-rules.md) · [docs/18 Decision Engine](../docs/18-health-decision-engine.md) · [why-ai-is-not-a-doctor.md](why-ai-is-not-a-doctor.md)
