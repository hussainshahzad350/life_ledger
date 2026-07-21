# Phase 14 — Performance

> Part of the [LifeLedger Specification](00-README-index.md). Depends on: [02](02-requirements.md), [03](03-architecture.md), [04](04-database-design.md). Feeds: [11](11-testing-strategy.md), [12](12-implementation-plan.md).

Performance is a **feature and an acceptance criterion**, not an afterthought ([01 §3](01-vision.md)).
This document turns the performance NFRs into concrete budgets, the techniques to hit them, and how we
measure them.

---

## 1. Budgets (targets, tied to NFRs)

| Area | Budget | NFR | Reference device |
|---|---|---|---|
| **App startup** (cold → interactive dashboard) | **≤ 1.5 s** | [NFR-1](02-requirements.md) | Mid-range (e.g., Snapdragon 6-series, 4 GB RAM) |
| Warm start | ≤ 600 ms | — | " |
| **Log save → dashboard reflects** | ≤ 200 ms perceived | [NFR-2](02-requirements.md) | " |
| **Report render (1-year range)** | ≤ 800 ms | [NFR-3](02-requirements.md) | " |
| **Frame rate** (scroll, timeline) | 60 fps, no dropped-frame jank | [NFR-4](02-requirements.md) | " |
| DB write (single entry) | ≤ 16 ms typical | — | " |
| Memory (steady state) | ≤ ~150 MB typical; no leaks | §7 | " |

Budgets are validated on the **reference device**, not just a flagship — the promise is "instant on a
mid-range phone."

---

## 2. Startup Time
- **Defer non-critical work:** only what the dashboard needs is initialized on the critical path; DI,
  DB open, and first query are lean; heavier services lazy-load.
- **Skeleton UI** renders immediately while the first aggregate query runs ([05 §6](05-uiux-system.md)) —
  no blank white screen.
- **DB open cost** minimized: single connection, `onConfigure` sets `foreign_keys=ON` cheaply;
  migrations only run on version change ([04 §7](04-database-design.md)).
- Avoid large synchronous asset loads (fonts/food-DB) on the startup path; the seed food DB imports
  lazily/incrementally, not during first paint.

## 3. Database Performance
- **Indexes** on every hot query path ([04 §6](04-database-design.md)) — dashboard "today", trends,
  timelines are index-backed.
- **`local_date`** stored at write time makes day-grouping a fast indexed string comparison instead of
  runtime timezone math ([04 §4.4](04-database-design.md)).
- Log tables are **write-heavy** → avoid over-indexing; each index is justified by a read path.
- Verify plans with `EXPLAIN QUERY PLAN` for the key queries; no full-table scans on the hot paths.

## 4. Query Performance
- **Aggregate in SQL, not Dart:** daily totals and report rollups use `SUM`/`GROUP BY local_date`
  rather than loading rows and summing in memory ([08 F10/F12](08-feature-specs.md)).
- Reports over long ranges **paginate/stream** and cap points for charts (downsample for display).
- Cache the current day's computed totals in the dashboard Bloc; invalidate on write.

## 5. Large Timeline Rendering
- Journal/timeline uses **lazy list building** (`ListView.builder`/slivers) — only visible items build.
- Stable keys + `const` widgets to minimize rebuilds; avoid rebuilding the whole list on a single edit
  (targeted state updates, [03 §2](03-architecture.md)).
- Group headers (meals) computed once per day window, not per row.

## 6. Image Caching (future-facing)
- v1 has minimal imagery. When food/meal images arrive (image logging, [07 §8](07-ai-rules.md)):
  - cache decoded images at display resolution (not source size);
  - bound the cache (count + bytes); evict LRU;
  - store originals in app-private storage, referenced by id — never re-decode on every scroll.

## 7. Memory Budget
- Steady-state target ~≤ 150 MB; **no leaks** (Blocs/streams/controllers disposed).
- Stream subscriptions closed with their Bloc; images bounded (§6); large query results streamed, not
  fully materialized.
- Leak checks via DevTools during QA ([11](11-testing-strategy.md)); regressions block release.

## 8. Battery Usage
- **No background polling** and no network in core flows → near-zero idle drain.
- Local notifications are scheduled via the OS scheduler (no wake-lock loops) ([08 F13](08-feature-specs.md)).
- Insight generation runs on a modest schedule/on-demand, off the UI isolate, not continuously ([07 §9](07-ai-rules.md)).
- Future wearable/Health Connect sync must be batched and OS-friendly ([15](15-release-roadmap.md)).

## 9. Offline Performance Targets
Because everything is local ([why-offline-first.md](../decisions/why-offline-first.md)), offline is the
*normal* case, not a degraded one: **all budgets in §1 assume no network.** There is no network-induced
latency in any core flow. Any future sync runs in the background and never blocks a user action.

## 10. Measuring & Guarding
- **Profile from milestone M4** ([12](12-implementation-plan.md)) on the reference device — measure, don't guess.
- Track: cold start, key query times, frame build/raster times, memory.
- Where feasible, add performance checks to CI/QA; a measured regression past budget **blocks merge**
  ([10 §10](10-coding-standards.md)).
- Heavy work (report aggregation, import, insight runs) goes **off the UI isolate** when profiling shows
  it matters ([03 §5](03-architecture.md)) — measured, not speculative.

---

*Next: [Phase 15 — Release Roadmap](15-release-roadmap.md).*
