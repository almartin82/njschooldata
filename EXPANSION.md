# njschooldata Expansion Research

**Last Updated:** 2026-06-26
**Theme Researched:** Coverage-gap hunt — datasets NJ DOE posts that are interesting to a school/district leader but NOT yet integrated.

## Method

Cross-referenced the full NJ DOE published-data universe (School Performance Reports +
standalone downloads) against the package's actual `fetch_*` inventory. Everything already
shipped was discarded: chronic absenteeism, discipline/violence/HIB/police/arrests,
postsecondary enrollment, SGP growth, SAT/ACT/PSAT, AP/IB overall participation, CTE,
industry credentials, per-pupil spending, ESSA accountability status, 4/5/6-year grad
rates, EL population, WIDA ACCESS, special-ed classification/child-count/LRE, staff
demographics/experience/retention/ratios, directory, facilities, courses. The five below
are the genuine holes.

---

## Recommended Enhancements (ranked by interest-to-effort)

### 1. Restraint & Seclusion incidents (DARS workbooks)

- **What it measures:** School-level counts of physical restraint and seclusion events,
  in NJ's standalone Discipline & Restraint (DARS) Excel workbooks — separate from the
  violence/vandalism/HIB data the package already pulls.
- **Why a leader cares:** One of the highest-liability, most legally sensitive metrics in
  any building, concentrated in special-education settings. Rarely surfaced in a
  cross-district comparable way; a spike is a board-meeting-level event.
- **Source:** `https://www.nj.gov/education/vandv/annualreport/` (`/dars/`)
- **Format / Years:** Excel; 2022-23, 2023-24.
- **Gap check:** Package has `fetch_violence_vandalism_hib()`, `fetch_police_notifications()`,
  `fetch_arrests()` — but **no restraint/seclusion fetcher**. Distinct source.
- **Priority:** HIGH · **Complexity:** MEDIUM (net-new standalone source: URL discovery +
  schema work + new fetcher).
- **Caveat:** Verify the exact current `/dars/` path before wiring (the `vandv/` root 404'd
  to one fetch tool; resolves via the annual-report portal).

### 2. Staff evaluation outcomes + deep staffing history

- **What it measures:** (a) Summative educator **evaluation rating distributions**
  (how many teachers/principals land in each tier); (b) the long Certificated /
  Non-Certificated Staff FTE series back to **1999-2000**.
- **Why a leader cares:** Evaluation-rating distributions are a rarely-analyzed window into
  eval-system rigor and grade inflation ("are we evaluating honestly vs. our neighbors?").
  The 25-year staffing series shows hiring booms/busts no other source captures.
- **Source:** `https://www.nj.gov/education/doedata/staff/`,
  `https://www.nj.gov/education/doedata/cs/` (certificated),
  `https://www.nj.gov/education/doedata/ncs/` (non-certificated)
- **Format / Years:** Excel/ZIP; certificated staff 1999-2000 to 2025-26.
- **Gap check:** Package's staff fetchers are all **SPR-sourced (2018+)** — demographics,
  experience, retention, ratios. **No evaluation-rating fetcher** and **no pre-2018
  staffing history**.
- **Priority:** HIGH · **Complexity:** MEDIUM-HARD (net-new sources; long schema-drift
  window across 25 years).
- **Caveat:** `data/cs/` direct fetch 404'd once but portal lists `doedata/cs` as live —
  confirm exact path. Expect heavy schema drift across the historical series.

### 3. School-day length + student-to-device ratio ✅ DONE (fetch_school_day / fetch_device_ratios)

> Shipped: `fetch_school_day()` (2017-2025) and `fetch_device_ratios()`
> (2018-2025 except 2017/2020). Published duration/ratio strings preserved plus
> derived numeric `*_minutes` / `students_per_device`. School-level only. Tests
> anchor a verified source cell per year. Vignette: `nj-school-environment`.


- **What it measures:** Instructional minutes per day (`SchoolDay`) and the
  student-to-computing-device ratio (`DeviceRatios`), both school-level SPR sheets.
- **Why a leader cares:** Time-on-learning and digital equity are levers leaders directly
  control. Device ratio became a board obsession post-COVID with no easy benchmark.
- **Source:** SPR downloadable databases, `https://www.nj.gov/education/spr/download/`
- **Format / Years:** Excel/Access; 2015-16+ (school level).
- **Gap check:** These are the package's **own only-still-open Tier-2 SPR sheets**
  (`dev-docs/spr-coverage-gap.md`) — explicitly identified, not yet implemented.
- **Priority:** MEDIUM · **Complexity:** EASY (additional sheets in SPR workbooks the
  package already downloads + caches; mostly a new tidy cleaner). **Lowest-effort win.**

### 4. Advanced-coursework access & equity

- **What it measures:** Which advanced courses a school actually **offers**
  (`ABIBCoursesOffered`), AP/IB/dual-enrollment participation **by student group**
  (`AP_IB_Dual_PartStudentGroup`), and Structured Learning Experience participation
  (`SLE_Participation`).
- **Why a leader cares:** The rigor-access / tracking-equity question — not "how many took
  AP" (covered) but "do we even offer it, and who gets in, by race/income/disability." The
  most newsworthy equity story in most districts.
- **Source:** SPR downloadable databases, `https://www.nj.gov/education/spr/download/`
- **Format / Years:** Excel/Access; 2015-16+.
- **Gap check:** `fetch_ap_participation()` covers **overall** participation only; the
  courses-offered sheet and subgroup splits are uncovered Tier-3 sheets.
- **Priority:** MEDIUM · **Complexity:** EASY-MEDIUM (same SPR plumbing, more columns).
- **Caveat:** `fetch_ap_participation(2025)` already errors on the malformed 2024-25
  school-level sheet — expect the same parsing trap on these adjacent sheets.

### 5. Seal of Biliteracy — trends & by student group

- **What it measures:** Students earning the State Seal of Biliteracy over time
  (`SealofBiliteracy_Trends`, `_Summary`) and by student group (`_StudentGroup`).
- **Why a leader cares:** Multilingualism-as-asset is a fast-growing point of pride and a
  recruiting/marketing differentiator, especially in high-EL districts — reframes EL
  students as high-achievers rather than a deficit.
- **Source:** SPR downloadable databases, `https://www.nj.gov/education/spr/download/`
- **Format / Years:** Excel/Access; 2015-16+.
- **Gap check:** Only the **language-breakdown** sheet is wired up
  (`fetch_biliteracy_seal()`); summary, trend, and student-group sheets uncovered.
- **Priority:** MEDIUM · **Complexity:** EASY (additional SPR sheets; new tidy cleaner).

---

## Effort summary

| # | Dataset | Priority | Complexity | New source? |
|---|---------|----------|-----------|-------------|
| 1 | Restraint & seclusion (DARS) | HIGH | MEDIUM | Yes — standalone |
| 2 | Staff evaluation + deep history | HIGH | MEDIUM-HARD | Yes — standalone |
| 3 | School-day length + device ratio | MEDIUM | EASY | No — SPR sheets |
| 4 | Advanced-coursework access/equity | MEDIUM | EASY-MEDIUM | No — SPR sheets |
| 5 | Seal of Biliteracy trends/group | MEDIUM | EASY | No — SPR sheets |

- **#3, #4, #5** are additional sheets in SPR workbooks the package already downloads and
  caches (`fetch_spr_data()` / `fetch_spr_sheet_raw()`) — mostly new tidy cleaners. Fast.
- **#1, #2** are net-new standalone sources (new fetcher + URL discovery + schema work) but
  the most distinctive and newsworthy.

## Excluded (already covered or disallowed)

- **Civil Rights Data Collection (CRDC) NJ extract** — excluded: federal-sourced *values*
  violate the no-federal-data rule (federal identifiers only).
- Chronic absenteeism, discipline/HIB/police/arrests, postsecondary (16-month), SGP,
  SAT/ACT/PSAT, AP/IB overall, CTE/credentials, per-pupil spending, ESSA status, ACGR
  grad rates, EL population, IDEA classification/child-count/LRE, dropout rates — all
  already shipped.

## Next steps (when implementing)

For each: enumerate all source files/years, HEAD-check URLs, download 3 sample years
(earliest/middle/latest), document column-name drift per year, confirm ID format
(preserve leading zeros, character type), establish time-series heuristics, then write
raw-fidelity tests FIRST (one verified value per year) before the get_raw / process /
tidy functions. Follow the 8-category LIVE pipeline test framework.
