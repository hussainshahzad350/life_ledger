# Decision Fatigue

> [Behavioral Science index](00-index.md). Applied in [docs/16](../../docs/16-behavioral-design.md).

## Concept
Decision fatigue is the decline in decision quality after making many decisions — willpower and
attention are finite. Every extra choice an app demands spends some of the user's limited budget.

## Why it matters
A health app that asks users to make dozens of tiny decisions per log (which units? which meal? search
from scratch?) burns them out. **Fewer, smarter defaults** = more logging = more value. This is the
mechanism behind the < 10s promise.

## Evidence
- Decision/ego-depletion literature (some effects debated/replication-limited — hedge). **C** `[verify]`
- Choice-overload effects. **B/C** `[verify]`

## How LifeLedger applies it
- **Smart defaults:** meal slot pre-selected by time of day; unit from profile; quantity stepper
  ([docs/05 §5.2](../../docs/05-uiux-system.md)).
- **Recents/Favorites first:** the common case is a single tap, no decisions.
- **Progressive disclosure:** advanced options hidden until needed; onboarding minimal.
- **One primary action** on the dashboard, not a wall of equal choices.

## Anti-patterns to avoid
- Blank-search-box-first logging (maximum friction).
- Settings sprawl surfaced to everyone.
- Asking for data the app can default or infer.

## Cross-links
[tiny-habits.md](tiny-habits.md) · [habit-formation.md](habit-formation.md) · [../../docs/05-uiux-system.md](../../docs/05-uiux-system.md)
