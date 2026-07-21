# Phase 16 — Behavioral Design

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [05](05-uiux-system.md), [knowledge/psychology](../knowledge/psychology/00-index.md). Feeds: [08](08-feature-specs.md).

> **"Never optimize only for technical architecture. Optimize for user behavior."**

This document is the **bridge** from behavioral science ([knowledge/psychology](../knowledge/psychology/00-index.md))
to concrete LifeLedger UX. It makes "optimize for behavior" a documented, testable design input.

---

## 1. The Core Behavioral Bet
LifeLedger's value requires **consistent, honest logging over weeks**. That is a behavioral outcome.
So we design to reduce friction and build a habit — never to exploit attention. Every technique here
must pass the ethical gate ([knowledge/psychology §2](../knowledge/psychology/00-index.md)):
> *Does this serve the user's own stated goal?* If not, we don't ship it.

---

## 2. Behavioral Principles → LifeLedger Mechanics

| Principle (knowledge link) | LifeLedger mechanic | Where |
|---|---|---|
| **Ability > motivation** ([tiny-habits](../knowledge/psychology/tiny-habits.md)) | The **< 10 s log**; recents/favorites; one-tap water | [05 §5.2](05-uiux-system.md), [08 F3/F4](08-feature-specs.md) |
| **Remove decisions** ([decision-fatigue](../knowledge/psychology/decision-fatigue.md)) | Smart defaults: meal slot by time, unit from profile, quantity stepper | [05 §5.2](05-uiux-system.md) |
| **Cue → routine → reward** ([habit-formation](../knowledge/psychology/habit-formation.md)) | Anchored opt-in reminders; dashboard as cue; instant progress rings as reward | [08 F13](08-feature-specs.md) |
| **Immediate feedback** ([reward-system](../knowledge/psychology/reward-system.md)) | Optimistic UI; rings fill on log (≤ 200 ms) | [05 §6](05-uiux-system.md), [14 §1](14-performance.md) |
| **Humane streaks** ([streak-psychology](../knowledge/psychology/streak-psychology.md)) | `STREAK_LOG` celebration; forgiveness/grace on a missed day; trend stays visible | [07 §3](07-ai-rules.md) |
| **Intrinsic motivation** ([motivation](../knowledge/psychology/motivation.md)) | Autonomy (override any goal), competence (small wins), "understand yourself" framing | [08 F2](08-feature-specs.md), [01](01-vision.md) |
| **Stages of change** ([behavior-change](../knowledge/psychology/behavior-change.md)) | Skippable onboarding + instant defaults; insights sustain long-term users | [08 F1](08-feature-specs.md), [07](07-ai-rules.md) |
| **Identity habits** ([atomic-habits](../knowledge/psychology/atomic-habits-concepts.md)) | "You're becoming someone who understands their body" framing; never guilt | [01](01-vision.md) |

---

## 3. The First-Run Behavioral Flow
1. **Zero-friction start:** onboarding is skippable; defaults let a user log within seconds ([08 F1](08-feature-specs.md)).
2. **First win fast:** the first log fills a ring immediately — an early reward that seeds the habit.
3. **Anchor the cue:** if the user opts into reminders, anchor them to natural moments (after breakfast),
   not arbitrary clock times ([tiny-habits](../knowledge/psychology/tiny-habits.md)).
4. **Payoff by day 7:** the first insight ([07](07-ai-rules.md)) arrives within a week
   ([01 §7](01-vision.md)) — the intrinsic reward of *learning something about yourself*.

---

## 4. Copy & Tone Rules (behavioral)
- **Supportive, never shaming.** No "you failed." Missing a day is normal ([05 §1](05-uiux-system.md)).
- **Progress framing.** Emphasize trend and effort over any single miss.
- **Honest rewards.** Celebrate real adherence; never fake urgency or FOMO.
- **Autonomy language.** "You can try…", not "You must…". Suggestions are reversible experiments
  ([07 §6](07-ai-rules.md)).

---

## 5. Dark Patterns We Explicitly Refuse
Documented so reviewers can reject them on sight ([knowledge/psychology reward-system anti-patterns](../knowledge/psychology/reward-system.md)):
- Hostage streaks that shame on reset.
- Guilt/FOMO notifications; nagging.
- Variable-reward loops tuned for app-opens; infinite scroll.
- Rewarding engagement over health outcomes.
- Comparison/leaderboards (explicit non-goal, [01](01-vision.md)).

---

## 6. Measuring Behavioral Success (privacy-safe)
Consistent with [01 §7](01-vision.md) (no silent telemetry): validate via **usability testing** and
**optional, explicitly-consented, on-device** self-report — never covert analytics ([why-no-ads.md](../decisions/why-no-ads.md)).
- Time-to-first-log, time-to-first-insight, self-reported "I learned something."
- Streak-forgiveness reduces rage-quits after a missed day (qualitative).

---

## 7. Behavioral Design in the Definition of Done
For any UX PR:
- Does it reduce friction or add it? Added friction needs justification.
- Does it use a documented principle here — or an anti-pattern? Anti-patterns block merge.
- Is the tone supportive and autonomy-preserving?

---

*Next: [Phase 17 — Food Database](17-food-database.md).*
