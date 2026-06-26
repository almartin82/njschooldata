## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

**NEVER fabricate data in ANY form.** This is the single most important rule in the entire project. Violations include but are not limited to:

- **Random generation:** `rnorm()`, `runif()`, `set.seed()`, `sample()`, `rlnorm()`, `rgamma()`, or any random number generation
- **Hardcoded numbers:** Hand-typing enrollment counts in `tribble()`, `data.frame()`, `tibble()`, or any other data structure. If a human typed the number instead of downloading it from a state DOE, it is fabricated.
- **"Plausible-looking" fake data:** Creating numbers that look real but aren't — smooth monotonic trends, round numbers, demographically "reasonable" percentages applied uniformly. This is the WORST form of fabrication because it is designed to deceive.
- **`create_example_data()` functions:** Helper functions that generate fake datasets, regardless of how realistic they look
- **Fixed demographic percentages:** Applying constant demographic ratios across all years/districts (real demographics change year to year)
- **Uniform grade distributions:** Using the same grade-level percentages for every district (real districts vary significantly)

**The test is simple: can you trace every number back to a downloaded file from a state DOE website?** If not, it is fabricated. There is no gray area. If the data source is unavailable, the package MUST use Under Construction status — not fake data.

---


# CLAUDE.md

## Project Overview
R package for fetching and processing New Jersey school data from the NJ Department of Education.

## Reference Docs (`dev-docs/`)

Detailed reference lives in `dev-docs/`. This file holds the always-on rules; load
the relevant doc only when the trigger applies, to keep context lean.

| Doc | Load when |
|-----|-----------|
| [`dev-docs/enrollment-filter-values.md`](dev-docs/enrollment-filter-values.md) | Writing `filter()` calls against `fetch_enr(tidy = TRUE)`, authoring enrollment stories, or a filter silently returns 0 rows |
| [`dev-docs/vignette-authoring.md`](dev-docs/vignette-authoring.md) | Editing any vignette `.Rmd`, regenerating/restyling charts, or debugging stale/missing charts (committed-PNG + knitr cache rules) |
| [`dev-docs/pkgdown-deploy.md`](dev-docs/pkgdown-deploy.md) | Configuring or debugging the pkgdown deploy, editing `_pkgdown.yml`, or enabling Pages on a new repo |
| [`dev-docs/data-source-urls.md`](dev-docs/data-source-urls.md) | A fetcher 404s / returns HTML, a download is empty, or a fetch URL needs updating for a new year |
| [`dev-docs/spr-coverage-gap.md`](dev-docs/spr-coverage-gap.md) | Triaging which redesigned 2024-25 SPR sheets to expose as new fetchers, or scoping SPR coverage work |
| [`dev-docs/tges-coverage.md`](dev-docs/tges-coverage.md) | Working on `fetch_tges()`/`get_raw_tges()`/`tidy_tges_data()`, adding a new TGES year, a TGES download 404s, or scoping TGES coverage |

## Vignette Code Must Run

Vignette analysis code MUST live in executable ` ```{r} ` chunks that run during the build and print real output — never static ` ```r ` fences, which render code with no output and ship unverified (this hid wrong sheet/column names for years in `spr-dictionary.Rmd`). Validate every sheet name, column, and filter value against actual function output before committing; reserve `eval = FALSE` for install commands, disk-writing examples, and intentionally-skipped slow network calls.

## Project Structure - PUBLIC vs PRIVATE

**njschooldata is a PUBLIC, OPEN SOURCE project.** Only general-purpose infrastructure code belongs in the package itself (`R/`, `tests/`, etc.).

| Location | Visibility | Purpose |
|----------|------------|---------|
| `R/`, `tests/`, `man/` | **PUBLIC** | General-purpose functions for fetching/processing NJ school data |

**Guidelines:**
- Code that could benefit any user of NJ school data → goes in `R/`
- Code specific to a particular research question or district → goes in `research-private/`
- Helper functions created during research that are general-purpose → refactor into `R/`
- District-specific constants, analysis scripts, cached data → stay in `research-private/`

## Commit Guidelines
- Do NOT include Claude's name, "Co-Authored-By", or any AI attribution in commit messages
- Keep commit messages concise and focused on the changes made

## Slash Commands
- `/deploy` - Full deployment pipeline: security review, tests, linter, build, deploy
- `/security-review` - Security audit of the package

## Testing
Run tests with: `devtools::test()` or `Rscript -e "devtools::test()"`

**Note:** Tests are disabled in CI/CD due to NJ DOE network dependencies. Run locally before deploying.

## Federal NCES id linkage (enrollment)

`fetch_enr()` attaches two federal identifier columns to BOTH wide and tidy
output (regardless of the `tidy` default):

- `nces_dist` — 7-digit NCES `LEAID`. Present on district aggregate rows
  (`school_id == "999"`) and school rows. `NA` on state/county aggregate rows.
- `nces_sch` — 12-digit NCES `NCESSCH`. Present on school rows only; `NA` for
  district/state/county rows.

**These are IDENTIFIERS, not data values.** Federal NCES ids are explicitly
allowed as join keys (see the parent `CLAUDE.md` "CRITICAL DATA SOURCE RULES"
and `docs/FEDERAL-NCES-LINKAGE.md`); the no-federal-data rule binds VALUES only.
All enrollment values still come from NJ DOE.

**How it works (Pattern C — state directory publishes NCES):** the NJ DOE
Homeroom directory carries the full 7-digit `NCES ID` keyed by the state's
County-District-School (CDS) code. The bundled crosswalk
(`inst/extdata/crosswalk/nj_nces_crosswalk.csv`) maps CDS →
`nces_dist`/`nces_sch`, with the 12-digit `NCESSCH` taken from CCD 2024 (joined
on district `LEAID` + 3-digit school code; NJ school codes are reused across
districts, so never join on the bare school code). `attach_nces_ids()` does an
exact CDS join — unmatched/ambiguous stays `NA`, never guessed.

**Rebuild the crosswalk:** `Rscript data-raw/build_nces_crosswalk.R` (vintage
2024). The build cross-validates every LEAID against the CCD 2024 NJ universe and
aborts on an implausibly large disagreement.

**Coverage / filter notes:** ~95% of districts and ~97% of schools match. Filter
real ids with `!is.na(nces_dist)` (an `nzchar()` filter alone passes `NA`).

## Valid Filter Values (finance)

`fetch_finance()` is the uniform, cross-state finance front door. It consolidates
the data `fetch_tges()` (per-pupil spending) and `fetch_state_aid()` (K-12 state
aid) already pull onto the canonical tidy schema in `docs/FINANCE-DATA-SPEC.md`.
Source-specific richness still lives in those functions and the `tges_*` toolkit.

- **FY <-> SY mapping:** `end_year` is the fiscal/school year END. `end_year = 2024`
  is FY2024 = school year 2023-24. NJ publishes a year's spending ACTUALS in the
  guide released the following year, so the spending side fetches
  `fetch_tges(end_year + 1)` and keeps `calc_type == "Actuals"`; state aid is
  appropriated for the named year and is read directly from `fetch_state_aid(end_year)`.
- **Year coverage:** per-pupil spending (TGES actuals) 2001-2024; state-aid revenue
  2019-2026. Years 2025+ carry `revenue_state` only; pre-2019 carry per-pupil only.
- **`metric`** (standard cross-state names first, then NJ-specific):
  - `per_pupil_total` (standard) - total per-pupil expenditures; carries a statewide
    `is_state` row and `enrollment_denominator` (avg daily enrollment + sent pupils)
  - `per_pupil_instruction` (standard) - classroom instruction per pupil
  - `per_pupil_support_services`, `per_pupil_administration`,
    `per_pupil_operations_maintenance`, `per_pupil_food_service` (NJ-specific:
    NJ reports these per-pupil, not as absolute totals; no `enrollment_denominator`)
  - `revenue_state` (standard) - total K-12 state aid, absolute dollars; carries a
    statewide `is_state` row
- **Entity flags:** `is_state` (statewide aggregate) XOR `is_district`; `is_school`
  always FALSE (NJ finance is district-level only); `is_charter` always NA (sources
  don't flag it).
- **`is_per_pupil`:** TRUE for every `per_pupil_*` metric, FALSE for `revenue_*`.
- **ids:** `state_id` is the 4-digit district code (Newark = "3570"); `nces_dist`
  is attached by district_id from the bundled crosswalk (~94% match), `nces_sch`
  always NA. Values are nominal dollars exactly as published - no rescaling, no
  fabrication; unmatched NCES ids and suppressed values stay NA.

## Valid Filter Values (English Learners)

`fetch_ell()` is the EL **population** front door (headcount + share of
enrollment), sourced from the NJ DOE Fall Enrollment files. It is distinct from
EL **proficiency** (`fetch_access()`, WIDA ACCESS). Tidy by default.

- **Year coverage:** 2006-2026 (`get_available_ell_years()`). Earlier
  enrollment files carry no EL column.
- **`el_status`:** always `"current"` — NJ publishes a single current-EL
  headcount, no former/monitored/ever-EL split.
- **`subgroup`:** always `"total"` — the EL count is not crossed by
  race/gender/grade.
- **`grade_level`:** always `"TOTAL"`.
- **Entity flags:** `is_state` XOR `is_district` XOR `is_school` (exactly one is
  TRUE per row; county aggregates are dropped). `is_charter` flags county 80.
- **`n_students` vs `pct_of_enrollment` (the COVID gap):** for **2020, 2021,
  2022** the NJ DOE *district* and *school* worksheets publish only an EL
  **percent**, not a headcount — for those entity-years `n_students` is `NA` and
  only `pct_of_enrollment` (0-100) is populated. The **statewide** count is
  published every year, and full counts at every level return from **2023** on.
  **NEVER back-derive the count from the percent** for the gap years.
- **Source-pipeline trap:** `get_raw_enr()` overwrites the published EL count
  with `pct * total` for 2020+ (its demographic-share workflow), so the
  enrollment `lep` subgroup is derived for those years. `fetch_ell()` reads the
  real `English Learners` / `Multilingual Learners` count column directly and
  must NOT reuse `get_raw_enr()`'s EL value for 2020+.
- **No suppression:** NJ does not suppress EL counts; `n_students_lower` ==
  `n_students_upper` == `n_students` wherever a count exists. Fractional `.5`
  values are real shared-time/vocational FTE, preserved as published.

## Valid Filter Values (school environment)

`fetch_school_day()` and `fetch_device_ratios()` read the school-only SPR
`SchoolDay` / `DeviceRatios` sheets. Both are **school-level only** (no
district/state aggregate; `level` must be `"school"`).

- **`fetch_school_day()` year coverage:** 2017-2025 (every year). The SY2016-17
  (2017) sheet omits the county/district/school **name** columns (CDS ids only);
  names are `NA` for 2017.
- **`fetch_device_ratios()` year coverage:** 2018, 2019, 2021, 2022, 2023, 2024,
  2025. The sheet is **absent from SY2016-17 (2017) and SY2019-20 (2020)** -
  those years error.
- **Published strings + derived numerics (deterministic parse, NOT fabrication):**
  - SchoolDay keeps `length_of_day`, `instruction_full_time`,
    `instruction_shared_time` as the published `"6 Hrs. 25 Mins."` strings and
    adds `length_of_day_minutes` / `instruction_full_time_minutes` /
    `instruction_shared_time_minutes`. Non-durations (`"n/a"`,
    `"n/a - applies only to high schools"`) -> `NA` minutes, never 0.
  - DeviceRatios keeps `student_device_ratio` (`"2.6:1"`; 2025 bare `"1"`) and
    adds numeric `students_per_device` (students per one device; 1 == 1:1).
    `"No devices reported"` / `"n/a"` -> `NA`.
- **No cross-level consistency check:** instructional minutes and device ratios
  are per-building attributes, not summable to a district/state total.
- **Entity flags:** `is_school` is TRUE for the per-school rows; the School
  workbook also carries a single district-aggregate placeholder row some years.
  `is_charter` flags county 80.

## Valid Filter Values (Seal of Biliteracy)

The Seal of Biliteracy has four fetchers. The per-language detail is covered by
`fetch_biliteracy_seal()` (legacy `SealofBiliteracy` 2018-2024, redesigned
`SealofBiliteracy_Language` 2025) - do NOT confuse it with the three
summary/trend/group fetchers below, which read sheets that exist **only in
end_year 2025** (introduced by the 2024-25 SPR redesign; absent 2017-2024). All
three are **2025-only** and error for any other year, and accept
`level = "school"` or `"district"`.

- **`fetch_biliteracy_summary()`** (`SealofBiliteracy_Summary`): per entity,
  `total_seals_earned`, `numberof_languages`, `unique_students_earning_seals`
  (+ `_pct`), `multilingual_learners_earning_seals` (+ `_pct`). The District
  workbook adds `schools_earning_seals(_pct)` and `districts_earning_seals(_pct)`
  (absent from the School workbook). The statewide `is_state` row lives in the
  **district** file (school file has no state row).
- **`fetch_biliteracy_trends()`** (`SealofBiliteracy_Trends`): **multi-year
  inside the 2025 workbook** - one row per entity per `school_year`, values
  `"2020-21"` .. `"2024-25"` (always 5 distinct years), with
  `total_seals_earned`. Do NOT filter to a single year.
- **`fetch_biliteracy_by_group()`** (`SealofBiliteracy_StudentGroup`): per entity
  and `subgroup`, `students_earning_seal_pct_school` (School workbook only),
  `students_earning_seal_pct_district`, `students_earning_seal_pct_state`. This
  sheet has **no statewide `is_state` row**; the state rate is carried in the
  `_pct_state` column on every row. Subgroups are normalized by
  `clean_spr_subgroups` (e.g. `total population`, `economically disadvantaged`,
  `limited english proficiency`, `hispanic/latino`,
  `asian, native hawaiian, or pacific islander`, `students with disabilities`,
  `female`, `male`, `white`, `black`, `multiracial`, etc.).
- **Suppression / text-bleed -> NA (NEVER a guessed number):** `spr_value_numeric`
  strips `%` and thousands commas and maps every non-numeric token to `NA`. A
  real published `0` stays `0`. Strings seen in the wild that must become `NA`:
  `"Fewer than 5 seals"` (trends), `"Enrollment for the group is <10 students."`
  / `"Fewer than 5 students earned a seal."` (by group),
  `"Total Current and Former ML enrollment was less than 10 students."` /
  `"Fewer than 5 students."` (summary ML text-bleed into the value column).
- **Rates can exceed 100%:** a few small high schools publish a group
  seal-earning rate above 100% (e.g. Kingsway Regional HS LEP `"109.1%"`) because
  the rate uses a 12th-grade-style denominator, not the group's own enrollment.
  These are real published cells - pass them through, do not clip. The
  `_pct_state` column stays a sane share (<= ~25%).
- **Entity flags:** standard SPR flags (`is_state`/`is_county`/`is_district`/
  `is_school`/`is_charter`/`is_charter_sector`/`is_allpublic`); `is_charter`
  flags county 80.

## Caching

Two layers, both on by default.

**1. Session cache (in-memory, per parsed sheet)** — avoids re-parsing within a session:
- `njsd_cache_info()` - view cache status
- `njsd_cache_clear()` - clear cache
- `njsd_cache_enable(FALSE)` - disable caching

The cache validates responses and will NOT cache network errors or bot protection pages.

**2. SPR workbook cache (on-disk, per year+level)** — the SPR Excel databases are
large (the 2024-25 District file is ~119 MB, the School file ~350 MB) and hold dozens
of sheets. `fetch_spr_data()`, `fetch_spr_sheet_raw()`, and `list_spr_sheets()` download
each workbook at most once and reuse the cached copy across sheet reads and across
sessions (reading a second sheet from the same workbook drops from ~12s to ~0.1s):
- `njsd_workbook_cache_dir()` - cache location (defaults to `tools::R_user_dir("njschooldata", "cache")`; override with `options(njschooldata.cache_dir=)`)
- `njsd_workbook_cache_info()` - list cached workbooks and sizes
- `njsd_workbook_cache_clear()` / `njsd_workbook_cache_clear(end_year)` - delete cached workbooks
- disable with `options(njschooldata.workbook_cache = FALSE)`

Downloads are validated as real `.xlsx` (ZIP magic bytes) before being cached, so an
HTTP error or bot-protection page is never written to the cache or parsed as data.
SPR workbooks for past years are static snapshots; clear the cache to force a refresh.
