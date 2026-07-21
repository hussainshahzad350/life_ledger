# Behavioral Science — Index

> **"Never optimize only for technical architecture. Optimize for user behavior."**
> This sub-base captures the psychology LifeLedger designs around. It is applied to concrete UX in
> [docs/16 — Behavioral Design](../../docs/16-behavioral-design.md).

Return to the [Knowledge Base index](../00-index.md) · [specification index](../../docs/00-README-index.md).

---

## 1. Why behavior is a first-class input

A perfectly-architected health app that people stop using has failed. Retention and honest logging
are *behavioral* outcomes, not technical ones. LifeLedger treats behavior-change principles as
design requirements with the same weight as performance or privacy — and, per
[docs/01 §7](../../docs/01-vision.md), measures success by understanding delivered, not vanity engagement.

## 2. Ethical guardrail (non-negotiable)

We use behavioral science to **reduce friction and build healthy habits**, never dark patterns.
No manipulative streaks-as-hostage, no guilt-driven notifications, no engagement-for-engagement's-sake.
Every technique here must pass: *"Does this serve the user's own stated goal?"* If not, reject it.
This aligns with [why-no-ads.md](../../decisions/why-no-ads.md) — attention is not the product.

## 3. Template (per behavioral file)

| Section | Content |
|---|---|
| **Concept** | The principle, plainly. |
| **Why it matters** | Its relevance to a health journal. |
| **Evidence** | Public frameworks/authors; Evidence Level tag; `[verify]` where exact citations pending. |
| **How LifeLedger applies it** | Concrete UX links (features/screens in [docs/05](../../docs/05-uiux-system.md)/[docs/08](../../docs/08-feature-specs.md)). |
| **Anti-patterns to avoid** | The dark-pattern version we explicitly refuse. |

Evidence Levels use the same [A–D scale](../00-index.md#3-evidence-level-scale). Note: behavioral
science is often B/C — we tag honestly and avoid over-claiming.

## 4. Contents

- [habit-formation.md](habit-formation.md) — cue → routine → reward; making logging automatic.
- [motivation.md](motivation.md) — intrinsic vs extrinsic; self-determination (autonomy/competence/relatedness).
- [streak-psychology.md](streak-psychology.md) — streaks that encourage without punishing.
- [behavior-change.md](behavior-change.md) — stages of change; small wins.
- [tiny-habits.md](tiny-habits.md) — Fogg Behavior Model (B=MAP); anchoring tiny actions.
- [atomic-habits-concepts.md](atomic-habits-concepts.md) — make it obvious/attractive/easy/satisfying.
- [decision-fatigue.md](decision-fatigue.md) — fewer choices, smart defaults, the <10s log.
- [reward-system.md](reward-system.md) — variable reward, progress, dopamine — used gently.

## 5. Attribution note

Named frameworks (e.g., the **Fogg Behavior Model / Tiny Habits** by BJ Fogg; **habit loop**
popularized by Charles Duhigg; **Atomic Habits** concepts by James Clear; **Self-Determination
Theory** by Deci & Ryan) are attributed to their public authors and described conceptually. Exact
page/edition citations are tagged `[verify]`; no quotations or figures are fabricated.
