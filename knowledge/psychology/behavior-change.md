# Behavior Change

> [Behavioral Science index](00-index.md). Applied in [docs/16](../../docs/16-behavioral-design.md).

## Concept
Behavior change is a process, not an event. The **Transtheoretical (Stages of Change) Model**
describes progression: precontemplation → contemplation → preparation → action → maintenance.
People need different support at each stage, and relapse is normal, not failure.

## Why it matters
A new LifeLedger user in "preparation" needs frictionless onboarding and quick wins; a long-term user
in "maintenance" needs to avoid boredom and stay engaged through insight, not novelty gimmicks.

## Evidence
- Transtheoretical Model — Prochaska & DiClemente. **B** `[verify]`
- Small-wins and self-efficacy in change — behavioral literature. **B/C** `[verify]`

## How LifeLedger applies it
- **Onboarding** is skippable with instant defaults → serve users not ready for full setup ([docs/08 F1](../../docs/08-feature-specs.md)).
- **Action stage:** the < 10s log + immediate feedback build early momentum.
- **Maintenance:** insights ([docs/07](../../docs/07-ai-rules.md)) provide ongoing value so the app stays
  useful after novelty fades.
- **Relapse-tolerant:** missing days is expected; the app re-engages gently, never with shame.

## Anti-patterns to avoid
- One-size-fits-all pressure (treating a curious newcomer like a committed power user).
- Framing relapse as failure.

## Cross-links
[motivation.md](motivation.md) · [tiny-habits.md](tiny-habits.md) · [streak-psychology.md](streak-psychology.md)
