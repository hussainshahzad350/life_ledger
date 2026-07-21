# LifeLedger Research — Source Registry Index

> The **citation backbone** of the [Knowledge Base](../knowledge/00-index.md). Every health claim in
> LifeLedger traces to a source registered here. This folder documents *which authorities we trust,
> why, and how we use them* — it is not a dump of raw papers.

Return to the [specification index](../docs/00-README-index.md).

---

## 1. Purpose

- Give every number and claim a **traceable provenance**.
- Separate **tier-1 authorities** (major public-health bodies) from individual studies.
- Make the "to-be-pinned" work explicit: anything not verifiable from memory is tagged **`[verify]`**
  so implementation can confirm the exact citation before it ships in-app.

## 2. Source Tiers

| Tier | Meaning | Examples |
|---|---|---|
| **T1** | Major guideline bodies / official datasets | WHO, USDA FoodData Central, IOM/NASEM DRIs, Dietary Guidelines for Americans, NIH ODS |
| **T2** | Named landmark studies / position stands | Mifflin–St Jeor (1990); professional-society position papers |
| **T3** | Emerging / mechanistic literature | Individual observational studies (tagged, hedged) |
| **T4** | Localized datasets (to source) | Pakistan/India food-composition tables `[verify]` |

The [Evidence Level scale](../knowledge/00-index.md#3-evidence-level-scale) (A–D) is assigned per
*claim*; the source tier describes the *authority*. A T1 body usually backs an A/B claim.

## 3. Registry

| Source | File | Used for |
|---|---|---|
| World Health Organization | [who.md](who.md) | Free-sugar limit, BMI categories, general population guidance |
| NIH (incl. Office of Dietary Supplements) | [nih.md](nih.md) | Nutrient roles, deficiency/upper-limit context |
| Dietary Guidelines for Americans | [dietary-guidelines.md](dietary-guidelines.md) | AMDR macro ranges, fiber, patterns |
| USDA FoodData Central | [usda.md](usda.md) | Food composition (seed food DB), Atwater factors |
| Pakistan nutrition data | [pakistan-nutrition-data.md](pakistan-nutrition-data.md) | Localized foods `[verify]` |
| Research papers register | [research-papers.md](research-papers.md) | Named equations & position stands (Mifflin–St Jeor, etc.) |

## 4. How to cite in the Knowledge Base

In a knowledge file's **Sources**/**References** sections, link to the registry file and name the
specific guidance, e.g.:

> Added-sugar ceiling: WHO free-sugars guideline → [research/who.md](who.md) · Evidence **A**.

If the exact document/edition/figure is not confirmed, append **`[verify]`**. Do **not** fabricate a
title, year, DOI, or numeric value to fill a gap.

## 5. Maintenance

- When a knowledge claim is added, ensure its source exists here (or add it).
- Resolve `[verify]` tags during implementation; record the confirmed citation and remove the tag.
- Licensing for any bundled dataset (esp. the seed food DB) is confirmed here before bundling
  (see [usda.md](usda.md) and [pakistan-nutrition-data.md](pakistan-nutrition-data.md)).
