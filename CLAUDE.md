# CLAUDE.md

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

**NEVER fabricate data in ANY form.** This is the single most important
rule in the entire project. Violations include but are not limited to:

- **Random generation:**
  [`rnorm()`](https://rdrr.io/r/stats/Normal.html),
  [`runif()`](https://rdrr.io/r/stats/Uniform.html),
  [`set.seed()`](https://rdrr.io/r/base/Random.html),
  [`sample()`](https://rdrr.io/r/base/sample.html),
  [`rlnorm()`](https://rdrr.io/r/stats/Lognormal.html),
  [`rgamma()`](https://rdrr.io/r/stats/GammaDist.html), or any random
  number generation
- **Hardcoded numbers:** Hand-typing enrollment counts in `tribble()`,
  [`data.frame()`](https://rdrr.io/r/base/data.frame.html), `tibble()`,
  or any other data structure. If a human typed the number instead of
  downloading it from a state DOE, it is fabricated.
- **“Plausible-looking” fake data:** Creating numbers that look real but
  aren’t — smooth monotonic trends, round numbers, demographically
  “reasonable” percentages applied uniformly. This is the WORST form of
  fabrication because it is designed to deceive.
- **`create_example_data()` functions:** Helper functions that generate
  fake datasets, regardless of how realistic they look
- **Fixed demographic percentages:** Applying constant demographic
  ratios across all years/districts (real demographics change year to
  year)
- **Uniform grade distributions:** Using the same grade-level
  percentages for every district (real districts vary significantly)

**The test is simple: can you trace every number back to a downloaded
file from a state DOE website?** If not, it is fabricated. There is no
gray area. If the data source is unavailable, the package MUST use Under
Construction status — not fake data.

------------------------------------------------------------------------

## Project Overview

R package for fetching and processing New Jersey school data from the NJ
Department of Education.

## Reference Docs (`dev-docs/`)

Detailed reference lives in `dev-docs/`. This file holds the always-on
rules; load the relevant doc only when the trigger applies, to keep
context lean.

| Doc | Load when |
|----|----|
| [`dev-docs/enrollment-filter-values.md`](https://almartin82.github.io/njschooldata/dev-docs/enrollment-filter-values.md) | Writing [`filter()`](https://rdrr.io/r/stats/filter.html) calls against `fetch_enr(tidy = TRUE)`, authoring enrollment stories, or a filter silently returns 0 rows |
| [`dev-docs/vignette-authoring.md`](https://almartin82.github.io/njschooldata/dev-docs/vignette-authoring.md) | Editing any vignette `.Rmd`, regenerating/restyling charts, or debugging stale/missing charts (committed-PNG + knitr cache rules) |
| [`dev-docs/pkgdown-deploy.md`](https://almartin82.github.io/njschooldata/dev-docs/pkgdown-deploy.md) | Configuring or debugging the pkgdown deploy, editing `_pkgdown.yml`, or enabling Pages on a new repo |
| [`dev-docs/data-source-urls.md`](https://almartin82.github.io/njschooldata/dev-docs/data-source-urls.md) | A fetcher 404s / returns HTML, a download is empty, or a fetch URL needs updating for a new year |
| [`dev-docs/spr-coverage-gap.md`](https://almartin82.github.io/njschooldata/dev-docs/spr-coverage-gap.md) | Triaging which redesigned 2024-25 SPR sheets to expose as new fetchers, or scoping SPR coverage work |
| [`dev-docs/tges-coverage.md`](https://almartin82.github.io/njschooldata/dev-docs/tges-coverage.md) | Working on [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)/[`get_raw_tges()`](https://almartin82.github.io/njschooldata/reference/get_raw_tges.md)/[`tidy_tges_data()`](https://almartin82.github.io/njschooldata/reference/tidy_tges_data.md), adding a new TGES year, a TGES download 404s, or scoping TGES coverage |

## Vignette Code Must Run

Vignette analysis code MUST live in executable ```` ```{r} ```` chunks
that run during the build and print real output — never static
```` ```r ```` fences, which render code with no output and ship
unverified (this hid wrong sheet/column names for years in
`spr-dictionary.Rmd`). Validate every sheet name, column, and filter
value against actual function output before committing; reserve
`eval = FALSE` for install commands, disk-writing examples, and
intentionally-skipped slow network calls.

## Project Structure - PUBLIC vs PRIVATE

**njschooldata is a PUBLIC, OPEN SOURCE project.** Only general-purpose
infrastructure code belongs in the package itself (`R/`, `tests/`,
etc.).

| Location | Visibility | Purpose |
|----|----|----|
| `R/`, `tests/`, `man/` | **PUBLIC** | General-purpose functions for fetching/processing NJ school data |

**Guidelines:** - Code that could benefit any user of NJ school data →
goes in `R/` - Code specific to a particular research question or
district → goes in `research-private/` - Helper functions created during
research that are general-purpose → refactor into `R/` -
District-specific constants, analysis scripts, cached data → stay in
`research-private/`

## Commit Guidelines

- Do NOT include Claude’s name, “Co-Authored-By”, or any AI attribution
  in commit messages
- Keep commit messages concise and focused on the changes made

## Slash Commands

- `/deploy` - Full deployment pipeline: security review, tests, linter,
  build, deploy
- `/security-review` - Security audit of the package

## Testing

Run tests with: `devtools::test()` or `Rscript -e "devtools::test()"`

**Note:** Tests are disabled in CI/CD due to NJ DOE network
dependencies. Run locally before deploying.

## Federal NCES id linkage (enrollment)

[`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
attaches two federal identifier columns to BOTH wide and tidy output
(regardless of the `tidy` default):

- `nces_dist` — 7-digit NCES `LEAID`. Present on district aggregate rows
  (`school_id == "999"`) and school rows. `NA` on state/county aggregate
  rows.
- `nces_sch` — 12-digit NCES `NCESSCH`. Present on school rows only;
  `NA` for district/state/county rows.

**These are IDENTIFIERS, not data values.** Federal NCES ids are
explicitly allowed as join keys (see the parent `CLAUDE.md` “CRITICAL
DATA SOURCE RULES” and `docs/FEDERAL-NCES-LINKAGE.md`); the
no-federal-data rule binds VALUES only. All enrollment values still come
from NJ DOE.

**How it works (Pattern C — state directory publishes NCES):** the NJ
DOE Homeroom directory carries the full 7-digit `NCES ID` keyed by the
state’s County-District-School (CDS) code. The bundled crosswalk
(`inst/extdata/crosswalk/nj_nces_crosswalk.csv`) maps CDS →
`nces_dist`/`nces_sch`, with the 12-digit `NCESSCH` taken from CCD 2024
(joined on district `LEAID` + 3-digit school code; NJ school codes are
reused across districts, so never join on the bare school code).
[`attach_nces_ids()`](https://almartin82.github.io/njschooldata/reference/attach_nces_ids.md)
does an exact CDS join — unmatched/ambiguous stays `NA`, never guessed.

**Rebuild the crosswalk:** `Rscript data-raw/build_nces_crosswalk.R`
(vintage 2024). The build cross-validates every LEAID against the CCD
2024 NJ universe and aborts on an implausibly large disagreement.

**Coverage / filter notes:** ~95% of districts and ~97% of schools
match. Filter real ids with `!is.na(nces_dist)` (an
[`nzchar()`](https://rdrr.io/r/base/nchar.html) filter alone passes
`NA`).

## Valid Filter Values (finance)

[`fetch_finance()`](https://almartin82.github.io/njschooldata/reference/fetch_finance.md)
is the uniform, cross-state finance front door. It consolidates the data
[`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
(per-pupil spending) and
[`fetch_state_aid()`](https://almartin82.github.io/njschooldata/reference/fetch_state_aid.md)
(K-12 state aid) already pull onto the canonical tidy schema in
`docs/FINANCE-DATA-SPEC.md`. Source-specific richness still lives in
those functions and the `tges_*` toolkit.

- **FY \<-\> SY mapping:** `end_year` is the fiscal/school year END.
  `end_year = 2024` is FY2024 = school year 2023-24. NJ publishes a
  year’s spending ACTUALS in the guide released the following year, so
  the spending side fetches `fetch_tges(end_year + 1)` and keeps
  `calc_type == "Actuals"`; state aid is appropriated for the named year
  and is read directly from `fetch_state_aid(end_year)`.
- **Year coverage:** per-pupil spending (TGES actuals) 2001-2024;
  state-aid revenue 2019-2026. Years 2025+ carry `revenue_state` only;
  pre-2019 carry per-pupil only.
- **`metric`** (standard cross-state names first, then NJ-specific):
  - `per_pupil_total` (standard) - total per-pupil expenditures; carries
    a statewide `is_state` row and `enrollment_denominator` (avg daily
    enrollment + sent pupils)
  - `per_pupil_instruction` (standard) - classroom instruction per pupil
  - `per_pupil_support_services`, `per_pupil_administration`,
    `per_pupil_operations_maintenance`, `per_pupil_food_service`
    (NJ-specific: NJ reports these per-pupil, not as absolute totals; no
    `enrollment_denominator`)
  - `revenue_state` (standard) - total K-12 state aid, absolute dollars;
    carries a statewide `is_state` row
- **Entity flags:** `is_state` (statewide aggregate) XOR `is_district`;
  `is_school` always FALSE (NJ finance is district-level only);
  `is_charter` always NA (sources don’t flag it).
- **`is_per_pupil`:** TRUE for every `per_pupil_*` metric, FALSE for
  `revenue_*`.
- **ids:** `state_id` is the 4-digit district code (Newark = “3570”);
  `nces_dist` is attached by district_id from the bundled crosswalk
  (~94% match), `nces_sch` always NA. Values are nominal dollars exactly
  as published - no rescaling, no fabrication; unmatched NCES ids and
  suppressed values stay NA.

## Valid Filter Values (English Learners)

[`fetch_ell()`](https://almartin82.github.io/njschooldata/reference/fetch_ell.md)
is the EL **population** front door (headcount + share of enrollment),
sourced from the NJ DOE Fall Enrollment files. It is distinct from EL
**proficiency**
([`fetch_access()`](https://almartin82.github.io/njschooldata/reference/fetch_access.md),
WIDA ACCESS). Tidy by default.

- **Year coverage:** 2006-2026
  ([`get_available_ell_years()`](https://almartin82.github.io/njschooldata/reference/get_available_ell_years.md)).
  Earlier enrollment files carry no EL column.
- **`el_status`:** always `"current"` — NJ publishes a single current-EL
  headcount, no former/monitored/ever-EL split.
- **`subgroup`:** always `"total"` — the EL count is not crossed by
  race/gender/grade.
- **`grade_level`:** always `"TOTAL"`.
- **Entity flags:** `is_state` XOR `is_district` XOR `is_school`
  (exactly one is TRUE per row; county aggregates are dropped).
  `is_charter` flags county 80.
- **`n_students` vs `pct_of_enrollment` (the COVID gap):** for **2020,
  2021, 2022** the NJ DOE *district* and *school* worksheets publish
  only an EL **percent**, not a headcount — for those entity-years
  `n_students` is `NA` and only `pct_of_enrollment` (0-100) is
  populated. The **statewide** count is published every year, and full
  counts at every level return from **2023** on. **NEVER back-derive the
  count from the percent** for the gap years.
- **Source-pipeline trap:**
  [`get_raw_enr()`](https://almartin82.github.io/njschooldata/reference/get_raw_enr.md)
  overwrites the published EL count with `pct * total` for 2020+ (its
  demographic-share workflow), so the enrollment `lep` subgroup is
  derived for those years.
  [`fetch_ell()`](https://almartin82.github.io/njschooldata/reference/fetch_ell.md)
  reads the real `English Learners` / `Multilingual Learners` count
  column directly and must NOT reuse
  [`get_raw_enr()`](https://almartin82.github.io/njschooldata/reference/get_raw_enr.md)’s
  EL value for 2020+.
- **No suppression:** NJ does not suppress EL counts; `n_students_lower`
  == `n_students_upper` == `n_students` wherever a count exists.
  Fractional `.5` values are real shared-time/vocational FTE, preserved
  as published.

## Caching

Two layers, both on by default.

**1. Session cache (in-memory, per parsed sheet)** — avoids re-parsing
within a session: -
[`njsd_cache_info()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md) -
view cache status -
[`njsd_cache_clear()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_clear.md) -
clear cache - `njsd_cache_enable(FALSE)` - disable caching

The cache validates responses and will NOT cache network errors or bot
protection pages.

**2. SPR workbook cache (on-disk, per year+level)** — the SPR Excel
databases are large (the 2024-25 District file is ~119 MB, the School
file ~350 MB) and hold dozens of sheets.
[`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md),
[`fetch_spr_sheet_raw()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_sheet_raw.md),
and
[`list_spr_sheets()`](https://almartin82.github.io/njschooldata/reference/list_spr_sheets.md)
download each workbook at most once and reuse the cached copy across
sheet reads and across sessions (reading a second sheet from the same
workbook drops from ~12s to ~0.1s): -
[`njsd_workbook_cache_dir()`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_dir.md) -
cache location (defaults to
`tools::R_user_dir("njschooldata", "cache")`; override with
`options(njschooldata.cache_dir=)`) -
[`njsd_workbook_cache_info()`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_info.md) -
list cached workbooks and sizes -
[`njsd_workbook_cache_clear()`](https://almartin82.github.io/njschooldata/reference/njsd_workbook_cache_clear.md)
/ `njsd_workbook_cache_clear(end_year)` - delete cached workbooks -
disable with `options(njschooldata.workbook_cache = FALSE)`

Downloads are validated as real `.xlsx` (ZIP magic bytes) before being
cached, so an HTTP error or bot-protection page is never written to the
cache or parsed as data. SPR workbooks for past years are static
snapshots; clear the cache to force a refresh.
