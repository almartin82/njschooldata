# CLAUDE.md

## CRITICAL DATA SOURCE RULES

**Federal IDENTIFIERS are allowed and ENCOURAGED.** The federal-source
ban applies to *values*, NOT to *join keys*. NCES identifiers (`LEAID` /
`NCESSCH`) and the CCD `state_leaid` / `seasch` crosswalk used purely to
attach them are explicitly welcome, and are bundled as a static,
versioned, identifiers-only asset under `inst/extdata/crosswalk/`.
Federal ids **supplement** the native state identifiers and never
replace them: every state-assigned district/school id must be preserved.
Do NOT delete `inst/extdata/crosswalk/`,
`data-raw/build_nces_crosswalk.R`, or any `attach_*nces*()` function —
the July-19 draft to ban federal ids outright was rejected (2026-07-24).
Every id must still trace to a real CCD row reached via a real state id:
match exactly, leave unmatched rows `NA`, never fabricate or fuzzy-guess
an id.

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

## `is_charter` is THREE-VALUED. Never guard the NA away. (REQUIRED)

NJDOE assigns every charter LEA to county `"80"` (its own County column
reads “Charters”), so the county code is the evidence, and it answers in
both directions:

| The source published | `is_charter` |
|----|----|
| county `"80"` | `TRUE` |
| any other county code (`"01".."41"`, `"99"`, a DFG letter, `"ST"`/`"NS"`/`"SN"`) | `FALSE` – a sourced fact, never sweep it into NA |
| no county code at all | `NA` |

**The banned idiom is `!is.na(x) & x == "80"`.** It reads as a careful
NA guard and is the exact opposite: it *cannot return NA*, so it answers
“not a charter” for every row the source never typed. `==` propagates NA
on its own; leave it alone. `dplyr::coalesce(x, FALSE)`,
`replace_na(x, FALSE)`, `any(x, na.rm = TRUE)` and `x %in% c(TRUE, "Y")`
are the same fabrication in other clothes.

[`is_charter_district()`](https://almartin82.github.io/njschooldata/reference/is_charter_district.md)
in `R/config_constants.R` is the single decider. Call it rather than
re-deriving; new surfaces get a case in
`tests/testthat/test-charter-provenance.R`, whose source scan fails on
any new NA-collapsing guard.

**The county-80 convention is VINTAGE-DEPENDENT.** Enrollment files use
county 80 only from `end_year` 2010; in 2006-2009 charters carry their
HOST county code (verified live: 50 name-charter LEAs in 2006-2008 sit
in counties 01, 07, 13 and 25, and county 80 does not appear at all). So
county 80 is affirmative evidence, never the sole basis for a denial in
a pre-2010 vintage. The bundled `charter_city` host map is likewise
affirmative-only: it lags NJ’s charter openings (it missed 4 real
county-80 charters in `end_year` 2026), so absence from it proves
nothing and must never demote a sourced TRUE.

Note that `is_charter_sector` is a different thing entirely – a
synthetic aggregate-ROW marker set by the `charter_sector_*_aggs()`
helpers, not a claim about any school – and is correctly initialised to
FALSE.

## Year Convention: njschooldata is END-year (verify external sources before joining)

Every fetcher in this package names a year by its **END year**:
`end_year = 2024` means school year 2023-24. This is the canonical
convention for all joins and trends.

**External or hand-supplied data may use a different convention and MUST
be checked before joining — never assume the raw year label matches.**
In particular, **ASSA (Application for State School Aid) is
collected/delivered in December**, so ASSA-derived series often carry a
**START-year** label, off by one from this package. An ASSA row labeled
`2025` may correspond to `end_year = 2026` here. Mismatched year
conventions are the prime suspect whenever an external series and an
njschooldata series disagree by exactly one year.

Before joining any external series to fetcher output: confirm the
convention (anchor on a known value, or apply the December-delivery →
start-year heuristic), convert everything to END-year, and document the
conversion. Treat year alignment as a validation gate, not an assumption
— a silent off-by-one corrupts every cohort-survival ratio,
decomposition, and trend.

------------------------------------------------------------------------

## Caching: point-in-time → CACHE. Always-on → NEVER cache. (REQUIRED)

**If it is a point-in-time release, we cache it, and we return the cache
by default.**

A state’s 2024 enrollment file is a frozen historical artifact —
published once, never revised. Enrollment, assessment, graduation,
finance, staff, SPED, ELL, absence, accountability and chronic absence
are all point-in-time. Bundle the source parent, serve it offline,
return the cached copy by default. Re-fetching a frozen release on every
call is pure waste.

**If it is an always-on source like a directory, we NEVER cache it.**

Directory data is a current-state register: school and district names,
addresses, contacts, grade spans, open/closed status, superintendents.
**It changes rapidly.** A cached copy is wrong almost immediately, and a
stale directory is worse than a slow one.
[`fetch_directory()`](https://almartin82.github.io/njschooldata/reference/fetch_directory.md)
and every directory surface acquires live from the state DOE on every
call. Do not add a cache layer to directory, do not bundle a directory
snapshot in `inst/extdata/`, and do not serve directory from a retained
parent.

**The test: would the state ever revise this same file in place?** Yes →
always-on source → live, never cached. No, they publish it once and move
on → point-in-time release → cached, returned from cache by default.

Regardless of live-vs-cached:

- **Never report a package bug as a source failure.** If the source
  responds correctly and our own parse, join or build then fails,
  [`stop()`](https://rdrr.io/r/base/stop.html) loudly — returning
  `source_unavailable` there blames the state DOE for our defect.
  Declaring a **genuine** upstream failure as a structured 0-row miss is
  correct and honest: that is `directory-contract/v1`, and it is what
  `nd` (upstream serving 153 bytes of HTML), `tn` (403) and `va` (500)
  correctly do. The test is not “did we return 0 rows” — it is **“did
  the source actually fail?”** Keep parsing OUTSIDE the acquisition
  `tryCatch`, and re-raise `directory_parse_error` /
  `directory_integrity_error` unchanged rather than downgrading them.
- **Federal NCES ids stay.** `nces_dist`/`nces_sch` and the CCD
  crosswalk belong alongside native state ids, in directory output as
  much as anywhere else. The July-19 draft banning federal ids was
  rejected on 2026-07-24. Never delete `inst/extdata/crosswalk/` or an
  `attach_*nces*()` function. Native state ids are never dropped or
  replaced.
- **Never fabricate a value.** If the source does not publish it, it
  stays missing and says so. This outranks everything above.
- **A capability gap is a DECLARATION, never a shutdown.** Never gate a
  working function to “Under Construction”, and never narrow an
  advertised catalogue to green a gate.

## A diverged parser or location invalidates the cache (REQUIRED)

A cached value is the output of one parser, run against one file, pulled
from one address. Change any of the three and the cached value is no
longer an answer to the caller’s question, even though it is still a
real state DOE number. No fabrication gate will catch it, because the
digits are genuine and only the binding is wrong.

**When you change a parser, processor, or tidier:** bump
`schema_version` for every affected family in `R/cache_registry.R`, and
recompute the derived cache from the retained source parent. Do not
re-download: point-in-time releases are frozen, and if the parent’s
checksum still verifies, re-pulling it is waste.

**When you change a download URL, endpoint, or anything about
acquisition:** bump `source_identity`, re-acquire from the state DOE,
then recompute everything downstream. Compare the new bytes against the
old. Identical is a fine answer and worth stating. Different is a
finding and must be reported, never absorbed silently.

**Record the reason inline**, next to the bump, in the style already
used in that file: what moved, what values it changed, and how many
cells. A bump with no reason is unreviewable, and the next person will
not know whether it is safe to coalesce.

**Never carry a stale value forward.** If re-acquisition fails, the year
is missing: declare it in `missing_years` or refuse. A carried-forward
value is exactly a number produced by code the package no longer has.

**Never report our own defect as a source failure.** If the source
answers correctly and our parse then fails,
[`stop()`](https://rdrr.io/r/base/stop.html) loudly.

Directory data is exempt from the cache half of this rule for the
obvious reason: it is always-on and never cached. The re-acquisition
half still applies.

Full text, the gate, and the list of packages currently in violation:
[docs/plans/2026-08-18-001-parser-divergence-invalidates-cache.md](https://almartin82.github.io/docs/plans/2026-08-18-001-parser-divergence-invalidates-cache.md).

## Federal sources: NEVER for DATA. The NCES↔︎state id crosswalk is a FEATURE. (REQUIRED)

**The one-line test: a federal VALUE is banned. A federal KEY is a
feature.**

**Never source DATA VALUES from a federal source** — not NCES CCD, not
the Urban Institute Education Data Explorer, not any federal aggregator
or API. Enrollment counts, demographics, assessment results, graduation
rates, finance figures and staff counts must all come from the state
DOE. Federal sources aggregate and transform differently and lose
state-specific detail, and that loss is the entire reason these packages
exist. If a state DOE source breaks, FIX IT or find another STATE source
— never fall back to federal data for a value.

**Shipping the bindings between NCES ids and native state ids is a
FEATURE**, not a tolerated exception. It is the bridge from this state’s
own identifiers to the national universe and to every NCES-keyed
consumer downstream. Ship it, document it, advertise it.

- Bundle the crosswalk as a **static, versioned, identifiers-only
  asset** in `inst/extdata/crosswalk/`, with a README noting the CCD
  vintage and stating that it carries **zero data values**. No runtime
  CCD calls.
- **Federal ids supplement, they never replace.** Every native state id
  must be preserved — never drop a state-assigned district or school id,
  never substitute a federal id for one. The state id is the primary
  identity; `nces_dist`/`nces_sch` sit alongside it.
- Every id must trace to a real CCD row reached via a real state id.
  Match exactly, leave unmatched rows `NA`, never fabricate or
  fuzzy-guess an id.

**Never delete `inst/extdata/crosswalk/`,
`data-raw/build_nces_crosswalk.R`, or any `attach_*nces*()` function**,
and never add a gate forbidding `nces_dist`/`nces_sch`. The July-19
draft to ban federal ids outright was **REJECTED on 2026-07-24**.

**Banned wording — delete on sight:** any blanket phrasing like “NEVER
use Urban Institute API, NCES CCD, or ANY federal data source”. An agent
reading that sentence alone concludes the crosswalk must go, and five
branches did exactly that on 2026-08-01. Always scope the ban to DATA
VALUES and state the crosswalk carve-out in the same breath, so the two
can never be read apart.

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
| [`dev-docs/live-test-inventory.md`](https://almartin82.github.io/njschooldata/dev-docs/live-test-inventory.md) | Adding or moving a test that might access a public source |
| [`dev-docs/source-outage-runbook.md`](https://almartin82.github.io/njschooldata/dev-docs/source-outage-runbook.md) | Operating a strict profile build or triaging source-result failures |

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

Offline tests are mandatory in pull-request CI and must remain
deterministic with no NJ DOE access. Live source assertions use the
shared opt-in flag `NJSCHOOLDATA_LIVE_TESTS=true`; without it they skip
consistently. A scheduled or manually dispatched canary workflow owns
live-source verification. Keep network- heavy vignette execution
separate from the offline test decision.

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
`dev-docs/FINANCE-DATA-SPEC.md`. Source-specific richness still lives in
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
  race/gender/grade. The additive `subgroup_std` column (inserted right
  after `subgroup`) standardizes this to `total_enrollment` for
  cross-domain joins.
- **`grade_level`:** always `"TOTAL"` — the NJ DOE fall-enrollment EL
  column publishes only a single current-EL total, with no by-grade
  breakdown (a grade split is never fabricated).
- **`with_status = FALSE` (opt-in honesty column):**
  `fetch_ell(..., with_status = TRUE)` appends a `value_status` column
  classified from the raw count token before coercion — `actual` where a
  count is published, `not_published` for the percent-only 2020-2022
  district/school entity-years (the count stays `NA` and is never
  back-derived from the percent). The WIDA ACCESS proficiency bridge
  \[[`fetch_access()`](https://almartin82.github.io/njschooldata/reference/fetch_access.md)\]
  carries `subgroup = "limited english proficiency"` /
  `subgroup_std = "lep"` so EL population joins to EL proficiency on the
  CDS id.
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

## Valid Filter Values (school environment)

[`fetch_school_day()`](https://almartin82.github.io/njschooldata/reference/fetch_school_day.md)
and
[`fetch_device_ratios()`](https://almartin82.github.io/njschooldata/reference/fetch_device_ratios.md)
read the school-only SPR `SchoolDay` / `DeviceRatios` sheets. Both are
**school-level only** (no district/state aggregate; `level` must be
`"school"`).

- **[`fetch_school_day()`](https://almartin82.github.io/njschooldata/reference/fetch_school_day.md)
  year coverage:** 2017-2025 (every year). The SY2016-17
  2017. sheet omits the county/district/school **name** columns (CDS ids
        only); names are `NA` for 2017.
- **[`fetch_device_ratios()`](https://almartin82.github.io/njschooldata/reference/fetch_device_ratios.md)
  year coverage:** 2018, 2019, 2021, 2022, 2023, 2024,
  2025. The sheet is **absent from SY2016-17 (2017) and SY2019-20
        (2020)** - those years error.
- **Published strings + derived numerics (deterministic parse, NOT
  fabrication):**
  - SchoolDay keeps `length_of_day`, `instruction_full_time`,
    `instruction_shared_time` as the published `"6 Hrs. 25 Mins."`
    strings and adds `length_of_day_minutes` /
    `instruction_full_time_minutes` / `instruction_shared_time_minutes`.
    Non-durations (`"n/a"`, `"n/a - applies only to high schools"`) -\>
    `NA` minutes, never 0.
  - DeviceRatios keeps `student_device_ratio` (`"2.6:1"`; 2025 bare
    `"1"`) and adds numeric `students_per_device` (students per one
    device; 1 == 1:1). `"No devices reported"` / `"n/a"` -\> `NA`.
- **No cross-level consistency check:** instructional minutes and device
  ratios are per-building attributes, not summable to a district/state
  total.
- **Entity flags:** `is_school` is TRUE for the per-school rows; the
  School workbook also carries a single district-aggregate placeholder
  row some years. `is_charter` flags county 80.

## Valid Filter Values (Seal of Biliteracy)

The Seal of Biliteracy has four fetchers. The per-language detail is
covered by
[`fetch_biliteracy_seal()`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_seal.md)
(legacy `SealofBiliteracy` 2018-2024, redesigned
`SealofBiliteracy_Language` 2025) - do NOT confuse it with the three
summary/trend/group fetchers below, which read sheets that exist **only
in end_year 2025** (introduced by the 2024-25 SPR redesign; absent
2017-2024). All three are **2025-only** and error for any other year,
and accept `level = "school"` or `"district"`.

- **[`fetch_biliteracy_summary()`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_summary.md)**
  (`SealofBiliteracy_Summary`): per entity, `total_seals_earned`,
  `numberof_languages`, `unique_students_earning_seals` (+ `_pct`),
  `multilingual_learners_earning_seals` (+ `_pct`). The District
  workbook adds `schools_earning_seals(_pct)` and
  `districts_earning_seals(_pct)` (absent from the School workbook). The
  statewide `is_state` row lives in the **district** file (school file
  has no state row).
- **[`fetch_biliteracy_trends()`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_trends.md)**
  (`SealofBiliteracy_Trends`): **multi-year inside the 2025 workbook** -
  one row per entity per `school_year`, values `"2020-21"` ..
  `"2024-25"` (always 5 distinct years), with `total_seals_earned`. Do
  NOT filter to a single year.
- **[`fetch_biliteracy_by_group()`](https://almartin82.github.io/njschooldata/reference/fetch_biliteracy_by_group.md)**
  (`SealofBiliteracy_StudentGroup`): per entity and `subgroup`,
  `students_earning_seal_pct_school` (School workbook only),
  `students_earning_seal_pct_district`,
  `students_earning_seal_pct_state`. This sheet has **no statewide
  `is_state` row**; the state rate is carried in the `_pct_state` column
  on every row. Subgroups are normalized by `clean_spr_subgroups`
  (e.g. `total population`, `economically disadvantaged`,
  `limited english proficiency`, `hispanic/latino`,
  `asian, native hawaiian, or pacific islander`,
  `students with disabilities`, `female`, `male`, `white`, `black`,
  `multiracial`, etc.).
- **Suppression / text-bleed -\> NA (NEVER a guessed number):**
  `spr_value_numeric` strips `%` and thousands commas and maps every
  non-numeric token to `NA`. A real published `0` stays `0`. Strings
  seen in the wild that must become `NA`: `"Fewer than 5 seals"`
  (trends), `"Enrollment for the group is <10 students."` /
  `"Fewer than 5 students earned a seal."` (by group),
  `"Total Current and Former ML enrollment was less than 10 students."`
  / `"Fewer than 5 students."` (summary ML text-bleed into the value
  column).
- **Rates can exceed 100%:** a few small high schools publish a group
  seal-earning rate above 100% (e.g. Kingsway Regional HS LEP
  `"109.1%"`) because the rate uses a 12th-grade-style denominator, not
  the group’s own enrollment. These are real published cells - pass them
  through, do not clip. The `_pct_state` column stays a sane share (\<=
  ~25%).
- **Entity flags:** standard SPR flags
  (`is_state`/`is_county`/`is_district`/
  `is_school`/`is_charter`/`is_charter_sector`/`is_allpublic`);
  `is_charter` flags county 80.

## Valid Filter Values (advanced course access)

`fetch_advanced_course_access(end_year, type, level)` is the single
front door over three SPR sheet families on advanced-coursework
ACCESS/EQUITY (distinct from
[`fetch_ap_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md),
which is overall AP/IB participation). Tidy by default; `level` is
`"school"` or `"district"`. Every rate/count is coerced with
`spr_value_numeric` (strips `%`/commas, maps suppression / “There is no
data available for this school year.” to `NA`, keeps a real `0`).

- **`type = "courses_offered"`** (`APIBCoursesOffered` 2017-2024 /
  `ABIBCoursesOffered` 2025 - the A-B-IB typo is the real 2025 sheet
  name): one row per school per advanced course. Cols `course_name`,
  `students_enrolled`, `students_tested` (counts). Years 2017-2025;
  error \<2017. The 2017 sheet omits the county/district/school **name**
  columns (CDS ids only) -\> names `NA` for
  2017. 
- **`type = "participation_by_group"`** (`APIBDualEnrPartByStudentGrp`
  2021-2024 / `AP_IB_Dual_PartStudentGroup` 2025): one row per entity
  per `subgroup` (normalized by `clean_spr_subgroups`;
  `total population` is the schoolwide total). Cols `apib_pct_school`,
  `apib_pct_state`, `dual_pct_school`, `dual_pct_state` always;
  `apib_pct_district`/`dual_pct_district` exist **only 2025**. Years
  2021-2025; **absent 2017-2020 -\> error \<2021**. The **2025 sheet is
  a multi-year trend table** (`school_year` 2020-21..2024-25) - filtered
  to the requested year with `filter_spr_to_year`. On the **legacy**
  `is_state` row the entity columns are `NA`; the statewide value is
  carried in `*_pct_state`.
- **`type = "sle"`** (Structured Learning Experience;
  `CTE_SLEParticipation` 2017-2023 - only the SLE columns surfaced, NOT
  CTE/IVC which stay in
  [`fetch_cte_participation()`](https://almartin82.github.io/njschooldata/reference/fetch_cte_participation.md)
  /
  [`fetch_industry_credentials()`](https://almartin82.github.io/njschooldata/reference/fetch_industry_credentials.md) -
  / `SLE_Participation` 2024-2025): one row per school. Entity rate is
  `sle_pct_school` (School workbook) or `sle_pct_district` (District
  workbook; also present in the 2025 School workbook), plus
  `sle_pct_state` always. Years 2017-2025; error \<2017. Published
  column names drift across BOTH year and level
  (`sleperc`/`sleschool`/`sledistrict`/`sle_school`/`sle_district`/`slestate`/
  `slestate_perc`/`sle_state`) and are detected-and-renamed onto the
  stable schema.
- **Genuine \>100 / cross-level note:** participation/SLE rates observed
  in \[0,100\]; pass any real published outlier through unclipped, never
  clip. Rates are per-entity shares and are NOT summable across levels.

## Valid Filter Values (restraint & seclusion)

`fetch_restraint_seclusion(end_year, level)` reads the standalone NJ DOE
DARS school-level Restraint & Seclusion workbook (source:
`nj.gov/education/vandv/annualreport/dars/`) - a source distinct from
[`fetch_violence_vandalism_hib()`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md).
Tidy output by default.

- **Year coverage:** `end_year` 2023 (SY2022-23) and 2024 (SY2023-24)
  only; any other year errors.
- **School-level only, NO aggregates:** `level` must be `"school"`
  (errors otherwise). Every row is a school: `is_school` is always TRUE,
  `is_state`/`is_county`/`is_district` always FALSE. The workbook has no
  state/district/county aggregate rows - do NOT invent them.
  `is_charter` flags county 80; `is_charter_sector`/`is_allpublic`
  always FALSE.
- **One row per (school, student_group).** The raw `student_group` is
  kept and also split into normalized `subgroup` + `grade_level`:
  - `subgroup` values: `total population` (the schoolwide total - raw
    `"Schoolwide"` in 2023, `"School Total"` in 2024),
    `american indian`, `asian`, `black`, `hispanic`, `pacific islander`,
    `multiracial`, `white`, `female`, `male`, `non-binary`,
    `economically disadvantaged`, `students with disabilities`.
  - `grade_level`: `TOTAL` for subgroup/schoolwide rows; grade rows
    carry `subgroup = "total population"` with `grade_level` in `PK`
    (raw `"Grade Preschool"`), `K` (`"Grade Kindergarten"`), `01`-`12`.
- **20 value columns** (count, percent pairs) across the 10 SSDS
  categories: `any_restraint_seclusion_*`, `restraint_*`,
  `restraint_physical_*`, `restraint_mechanical_*`,
  `restraint_both_phys_mech_*`, `seclusion_*`,
  `both_restraint_seclusion_*`, `both_physical_restraint_*`,
  `both_mechanical_restraint_*`, `both_phys_mech_restraint_*` (each
  `_count` + `_pct`).
- **Suppression -\> NA (NEVER a guessed number):** small cells are
  masked. `"*"` hides a value entirely; `"<5"` / `"<5.00"` is a
  published RANGE for 1-4 students.
  [`rs_value_numeric()`](https://almartin82.github.io/njschooldata/reference/rs_value_numeric.md)
  maps both (any `"<"` token or `"*"`) to `NA` BEFORE numeric parsing,
  so `"<5"` NEVER becomes the literal `5`. A real published `0` stays
  `0`. Do NOT back-derive a count from a percent.

## Valid Filter Values (staff evaluations + certificated staff)

Two standalone NJ DOE **doedata** staff sources (NOT SPR sheets),
distinct from the SPR-sourced
[`fetch_staff_demographics()`](https://almartin82.github.io/njschooldata/reference/fetch_staff_demographics.md)
/
[`fetch_spr_staff_counts()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_staff_counts.md)
etc. Both coerce values with `staff_value_numeric` (`"*"` / `""` / any
`"<N"` range / free text -\> `NA` BEFORE numeric parse; commas stripped;
a real `0` stays `0`; fractional FTE preserved).

- **`fetch_staff_evaluations(end_year, level)`** - summative educator
  evaluation rating distributions (source
  `nj.gov/education/doedata/staff/`). **Only three years exist: 2014,
  2015, 2016**; any other year errors. `level` is `"school"` (default)
  or `"district"`.
  - `staff_category`: `teachers` (raw `TEACHERS`), `principals_vps` (raw
    `PRIN/AP/VP`). Raw label kept as `category`.
  - rating cols: `ineffective`, `partially_effective`, `effective`,
    `highly_effective`, `total` (`"*"` -\> NA).
  - Entity flags: `is_school` (per-school) vs `is_district`
    (`school_id=="999"`). A **statewide** aggregate (county `"99"` /
    district `"9999"`) is published in **2014 and 2015** and flagged
    `is_state` (returned at `level="district"`); **2016 has no statewide
    row**. `is_charter` is county 80 (three-valued; NA where no county
    code is published). This file family contains NO charter LEA at all
    – 0 county-80 rows and 0 name-charter LEAs in all three years.
  - CDS drift: the 2015 (1415) file drops leading zeros (district
    `"10"`); ids are re-padded to county 2 / district 4 / school 3.
- **`fetch_certificated_staff(end_year, level)`** - certificated-staff
  FTE by position x race x gender (source
  `nj.gov/education/doedata/cs/`). Output is harmonized **long by
  gender** (one row per entity x position x gender; `gender` in
  `total`/`male`/`female`). `level` is `"school"` (default),
  `"district"`, `"county"`, `"state"`.
  - **Covered years: 2000-2008 (legacy CSV) and 2020-2026 (modern
    xlsx).** The **2009-2019** intermediate Excel files use a drifting,
    non-uniform layout and **error** (documented) - never guess.
  - `position`: `administrators`, `teachers`, `special_services`,
    `supervisors_coordinators`, `total` (the modern SCHOOL sheet has no
    `total` position row).
  - race FTE cols: `white`, `black`, `hispanic`, `asian`,
    `american_indian`, `pacific_islander`, `two_or_more`, plus `total`.
    **Era-absent -\> NA, never 0:** the legacy era reports a single
    combined Asian/Pacific-Islander bucket, so `asian` carries the
    combined count and `pacific_islander` + `two_or_more` are `NA` for
    2000-2008. Modern era populates all races (on the `gender=="total"`
    row only; `male`/`female` rows carry the gender headcount in `total`
    with race cols `NA`).
  - **FTE values are fractional doubles** (e.g. `35.8`) - never rounded.
    Non-binary staff are published only as a percent (no count) in
    modern files and are NOT surfaced as a count.
  - Legacy entity conventions inside the single CSV: state =
    `CONAME=="STATE SUM"`, county = `DIST=="9998"` (CO SUMMARY),
    district total = `SCH=="998"` (DIST SUMMARY), else school.
    `is_charter` is county 80 (three-valued). The **STATE SUM row
    publishes no county code** in 2000-2002 and 2020-2026, so its
    `is_charter` is `NA`, not FALSE (2003-2008 publish `"99"` there, a
    sourced FALSE). The 2000-2008 CSVs contain no charter LEA at all.
  - **Deferred:** the non-certificated (`ncs/`) series mirrors this but
    is not yet implemented.

## Valid Filter Values (SPR assessment / graduation detail “Bucket A”)

Five SPR sheets first published in (or, for federal grad rates, expanded
by) the redesigned 2024-25 School Performance Reports, with no
standalone-fetcher equivalent. All read via
[`fetch_spr_data()`](https://almartin82.github.io/njschooldata/reference/fetch_spr_data.md)
(CDS + standard entity flags), tidy by default, `level` is `"school"` or
`"district"`. Every value is coerced with `spr_value_numeric` (strips
`%`/commas, maps suppression / `"n/a"` / “Fewer than 10…” to `NA`, keeps
a real `0`); a published rate is NEVER clipped or back-derived.

**Shared entity-pick rule (the `{_school,_district,_state}` triple).**
Four of these sheets repeat every value as a school/district/state
triple on each row.
[`spr_pick_entity_value()`](https://almartin82.github.io/njschooldata/reference/spr_pick_entity_value.md)
collapses it like
[`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md):
at `level="school"` it takes `_school`; at `level="district"` it takes
`_district` for ordinary rows and `_state` ONLY for the statewide
`is_state` row (whose `_district` cell is blank). It never fills a
suppressed district from the state column. The statewide value is
therefore available from the `is_state` row of **district**-level
output, and the redundant `_state` reference columns are dropped from
the result.

**Pre-redesign backfill (`spr_legacy_entity_value`).** Three of these
fetchers extend back into the pre-2025 databases, where the sheets are
differently named and store the entity value in one column with the
statewide value repeated in a parallel `state_*` column (blank entity
cell on the `State` row). The shared
[`spr_legacy_entity_value()`](https://almartin82.github.io/njschooldata/reference/spr_legacy_entity_value.md)
collapses that the same way (`state_*` only on the `is_state` row,
entity column otherwise; never fill a suppressed entity from the
statewide column). Where the column name embeds the grade/test,
`grade_subject`/ `grade` is normalized to the 2025 `grade_test`
vocabulary by
[`normalize_grade_test()`](https://almartin82.github.io/njschooldata/reference/normalize_grade_test.md)
(`"Grade 03"`-\>`"Grade 3"`, `ALG01`/`ALG02`/`GEO01`-\>
`Algebra I`/`Algebra II`/`Geometry`).

- **`fetch_spr_proficiency_by_test(end_year, subject, level)`** -
  ELA/Math NJSLA proficiency split by the test taken (`grade_test`):
  grade-level tests Grade 3-9 PLUS the high-school end-of-course tests
  `Algebra I`, `Geometry`, `Algebra II` (Math). `subject` is `"ela"`
  (default) or `"math"`. Values `valid_scores`, `mean_scaled_score`,
  `proficiency_rate` (level 4+5), `level_1`..`level_5`. **Years
  2017-2019 and 2022-2025; 2020-2021 error** (no by-grade/test ELA/Math
  sheet - COVID). Sheets by era: 2025
  `ELAPerformanceByTest`/`MathPerformancebyTest` (multi-year trend,
  filtered to the requested year); 2022-2024
  `ELAPerformanceByGrade`/`MathPerformanceByGradeTest` (`grade_subject`,
  `percent_level_*`, `percent_testers_met_or_exceeded`); 2017-2019
  `ELALiteracyPerformanceByGrade`/`MathPerformanceByGradeTest` (`grade`,
  `level_*`, `met_exceed`). Anchors: 2025 statewide ELA Grade 4
  `proficiency_rate` = 53.5 / `valid_scores` = 93574, Math Algebra I =
  38.1; 2024 Math Algebra I = 40; 2019 Math Algebra I = 42.
- **`fetch_spr_science_grade(end_year, level)`** - NJSLA science by
  grade (5/8/11); `grade_level` normalizes `grade` to
  `"05"`/`"08"`/`"11"`. Values
  `level_1_percentage`..`level_4_percentage` (proficiency = levels 3+4,
  NOT summed here). **Years 2019 and 2021-2025; 2020 errors** (no spring
  2020 testing) and **2017-2018 error** (the earlier `NJASKScience` is a
  different scale, not mapped). Sheets by era: 2025
  `NJSLASciencebyGradeTrends`; 2022-2024 `ScienceAssessmentByGrade`
  (entity `percent_level_*`, state `performance_level_*_perc`); 2021
  `NJSLAScience`; 2019 `NJSLAScienceTable` (`level_1`..`level_4`
  direct). Anchors: 2025 statewide Grade 5 L1 = 30.6 / L4 = 7.9; 2024
  Grade 5 L4 = 6; 2019 Grade 5 L4 = 7.
- **`fetch_spr_elp_progress(end_year, level)`** - `ProgressTowardELP`.
  **2025-only**; distinct from the ELP *target* sheet
  (`ProgresstowardELPTargets`, in `fetch_spr_essa_targets`) and from the
  legacy target-bearing `EnglishLanguageProgress` (a different metric -
  deliberately NOT mapped; 2020 is COVID and 2021-2024 carry only ACCESS
  participation/performance). **No subgroup/grade** - one
  `progress_toward_elp` (entity-picked) per entity. Trend table;
  filtered to SY2024-25. Anchor: statewide = 30.1.
- **`fetch_spr_grad_cohort(end_year, level)`** - 4/5/6-year cohort
  outcome rates. One row per entity x `cohort_type`
  (`"4-Year"`/`"5-Year"`/`"6-Year"`) x subgroup, with `graduated` /
  `continuing` / `non_continuing` / `persisting` rates (0-100).
  `persisting` is published only for the 6-Year cohort (and only from
  `end_year` 2024 in the pre-redesign sheets) - else `NA`. **Years
  2020-2025; 2020 has 4/5-Year only** (no 6-Year sheet yet); error
  \<2020. Sheets: 2025 combined `GraduationCohortProfile`
  (entity-picked; `school_year` stamped as full-year `"2024-2025"`,
  which `filter_spr_to_year` now accepts); 2020-2024 stacks the separate
  `4Yr`/`5Yr`/`6YrGraduationCohortProfile` sheets
  (`graduates`/`state_graduates` etc. via `spr_legacy_entity_value`).
  The 4- and 6-year rates are also in
  [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
  /
  [`fetch_6yr_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md);
  this adds the 5-year cohort and all available lengths in one frame.
  Anchors: statewide 4-Year `graduated` 2025 = 91.8, 2024 = 91.3, 2020 =
  91.0.
- **`fetch_spr_fed_grad(end_year, level)`** - `FederalGraduationRates`,
  **2021-2025** (absent SY2016-17..SY2019-20 -\> error \<2021).
  Federally reported ACGR (different cohort denominator than
  [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)’s
  state rate). Reshaped **long by cohort**: one row per entity x
  subgroup x `cohort_years` (4/5/6), with `cohort_label`
  (e.g. `"Cohort 2025"`) and entity-picked `graduation_rate_federal`.
  **6-year cohort only from SY2023-24 (2024)**; 2021-2023 carry 4+5
  only. Heavy column drift handled by
  [`fed_grad_cols_for_n()`](https://almartin82.github.io/njschooldata/reference/fed_grad_cols_for_n.md):
  2025 names by cohort length (`x_4_yr_graduation_rate_federal_school` +
  a `school_year` column); 2021-2024 embed the graduating year in the
  name (`x_2024_4_year_federal_graduation_rate` / `state_2024_...`), and
  in that legacy layout the statewide value lives in the `state_*`
  column on the `State` row. `end_year` 2021 = SY2020-21. Anchors:
  statewide 4-yr = 88.9 (2025) / 85.2 (2022); Atlantic City (`0110`)
  4-yr 2022 = 66.5.

## Valid Filter Values (special education)

Two fetchers read NJ DOE IDEA-618 public-reporting special-education
data (source `nj.gov/education/specialed/monitor/ideapublicdata/docs/`).
Both carry the standard entity flags
(`is_state`/`is_county`/`is_district`/`is_school`/
`is_charter`/`is_charter_sector`/`is_allpublic`; `is_charter` is county
80, three-valued – `level = "state"` output carries no county column at
all, so its `is_charter` is `NA`) and an opt-in `with_status = FALSE`
arg (TRUE appends a `value_status` factor classified BEFORE numeric
coercion, so a suppressed cell is never a fabricated 0). Metric
polarity/denominator metadata is in `metric_registry.csv`
(`sped_rate`/`sped_num`/`gened_num`/`sped_num_no_speech`, and placement
`count`/ `percent`/`subgroup_total`).

- **`fetch_sped(end_year, level, with_status)`** - district
  classification rate. **`level = "district"` (default) covers every
  end_year 2015-2025**: the 2015-2024 archives live in the year-labeled
  folders/zips of the IDEA-618 directory (e.g. `docs/2020.zip` -\>
  `2020/Lea_Classification_Pub.xlsx`), 2025 is the consolidated
  `District Rates` sheet. Columns: `end_year`, `county_id`,
  `county_name`, `district_id`, `district_name`, `gened_num`,
  `sped_num`, `sped_rate` (+ flags). Rates are published shares - a few
  tiny/sending districts publish `sped_rate > 100` (e.g. 2018), passed
  through UNCLIPPED, never fabricated. **`level = "state"` (by IDEA
  disability category) is 2025-only** (`State Rates` sheet -\>
  `disability_category`, `n_students`, `sped_rate`, `suppressed`);
  earlier years have NO clean public-only state-by-disability workbook
  -\> honest error (not_published), NOT transcribed. Pre-2015 requires
  an OPRA request. `disability_category` is standardized snake_case with
  the `"Statewide Total"` rollup mapped to `all_disabilities`.
- **`fetch_sped_placement(end_year, age_group, level, tidy, with_status)`**
  /
  [`fetch_sped_placement_multi()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement_multi.md) -
  IDEA-618 educational-environment (LRE) placement, 2020-2025. `level`
  is `"district"` (default) or `"state"`; **`level = "school"` is
  rejected honestly** (NJ DOE publishes LRE at district/state only -
  school-level placement is not_published). `age_group` is `"5-21"`
  (default) or `"3-5"`. Tidy output adds `subgroup_std` immediately
  after `subgroup`: standard demographic subgroups map onto the shared
  vocabulary; placement-specific / non-demographic tokens (`total`,
  disability categories, `age_*`, `lep`, `native_american`) have NO
  standard demographic equivalent and carry `subgroup_std = NA` by
  design (the row’s dimension is in `dimension`). `with_status`
  classifies the `count` column (`actual`/`suppressed`; a `"*"` small
  cell is suppressed). Pre-2025 district 5-21 publishes counts only
  (`percent` is `NA` in those rows); state-level 2020-2022 slices ship
  from bundled transcribed-PDF CSVs.

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
