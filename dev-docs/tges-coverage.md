> Load this when: working on `fetch_tges()` / `get_raw_tges()` / `tidy_tges_data()`, adding a new TGES year, a TGES download 404s, or scoping what TGES data is (and isn't) exposed.

# TGES Coverage

## Background

The **Taxpayers' Guide to Educational Spending** (TGES) is NJ DOE's annual district
fiscal report. It was branded the **Comparative Spending Guide** (CSG) before 2011;
the file/table names keep the `CSG` prefix throughout. Each year ships as a single
zip containing one file per indicator table.

The package routes all access through three functions in `R/tges.R`:

- `get_raw_tges(end_year)` — download + unzip one year, return a named list of raw
  data frames (one per table file: `CSG1`, `CSG2`, …, `VITSTAT_TOTAL`).
- `tidy_tges_data(list, end_year)` — apply a per-table cleaner to reshape each wide
  table to long/tidy. **Unknown tables are returned as-is** (the cleaner lookup
  falls through).
- `fetch_tges(end_year)` — the two chained. `fetch_many_tges(years)` loops it.

This doc catalogues which tables have tidy cleaners, the year/format coverage, and
the few real gaps.

---

## Year & format coverage

| Years | Brand | Zip name | Member format(s) |
|---|---|---|---|
| 2001-2010 | CSG | `{year}_CSG.zip` | DBF (early) → CSV |
| 2011-2023 | TGES | `{year}_TGES.zip` | CSV / XLSX |
| 2024 | TGES | `2024/TGES24_Zipped.zip` (per-year subfolder) | XLSX |
| 2025 | TGES | `2025/TGES2025_Zipped.zip` (per-year subfolder) | XLSX |

- **Valid `end_year`: 2001-2025.** All built by `tges_url_for_year()` against the
  current `nj.gov/education/guide/docs/` base (the old `state.nj.us/education/guide/{year}/`
  paths were retired in the 0.9.8 fix — every one now 404s).
- `get_raw_tges()` reads CSV, XLSX, and DBF members (DBF support is retained for the
  earliest CSG-era files). Members live under a per-year subfolder inside the zip
  (e.g. `2011_TGES/CSG1.CSV`); the loader keys off the bare file name so the
  `tidy_tges_data()` lookups still match.

---

## Table → cleaner coverage (complete)

Every table the guide publishes has a tidy cleaner. There are **no untidied CSG
tables** in the historical (2001-2023) set.

| Table | Cleaner | What it holds |
|---|---|---|
| `CSG1AA_AVGS` | `tidy_total_spending_per_pupil` | Total expenditures, ADE + sent pupils, per-pupil total, per-pupil rank, budget/operating type |
| `CSG1` | `tidy_budgetary_per_pupil_cost` | Budgetary per-pupil cost |
| `CSG2` | `tidy_total_classroom_instruction` | Total classroom instruction |
| `CSG3` | `tidy_classroom_salaries_benefits` | Classroom salaries & benefits |
| `CSG4` | `tidy_classroom_general_supplies` | Classroom general supplies & textbooks |
| `CSG5` | `tidy_classroom_purchased_services` | Classroom purchased services & other |
| `CSG6` | `tidy_total_support_services` | Total support services |
| `CSG7` | `tidy_support_services_salaries` | Support services salaries + benefits |
| `CSG8` | `tidy_administrative_costs` | Total administrative costs per pupil |
| `CSG8A` | `tidy_legal_services` | Legal services per pupil |
| `CSG9` | `tidy_admin_salaries` | Salaries + benefits for administration |
| `CSG10` | `tidy_plant_operations_maintenance` | Operations & maintenance of plant |
| `CSG11` | `tidy_plant_operations_maintenance_salaries` | Salaries + benefits — operations/maintenance |
| `CSG12` | `tidy_food_service` | Food service cost per pupil + benefits |
| `CSG13` | `tidy_extracurricular` | Extracurricular costs per pupil + benefits |
| `CSG14` | `tidy_personal_services_benefits` | Employee benefits **as a % of total salaries** (not a $ per-pupil cost) |
| `CSG15` | `tidy_equipment` | Total equipment cost per pupil |
| `CSG16` | `tidy_ratio_students_to_teachers` | Student/teacher ratio + median teacher salary |
| `CSG17` | `tidy_ratio_students_to_special_service` | Student/special-service ratio + median salary |
| `CSG18` | `tidy_ratio_students_to_administrators` | Student/administrator ratio + median salary |
| `CSG19` | `tidy_ratio_faculty_to_administrators` | Faculty/administrator ratio |
| `CSG20` | `tidy_budgeted_vs_actual_fund_balance` | Budgeted general fund balance vs. actual |
| `CSG21` | `tidy_excess_unreserved_general_fund` | Excess unreserved general fund balances |
| `VITSTAT_TOTAL` | `tidy_vitstat` | Spending per pupil, revenue mix (state/local/federal/tuition/free-balance/other %), student-staff ratios, % SpEd |
| `DETAIL_FY##` | `tidy_total_spending_detail` | **2024+ bundles only.** Total Spending split into 6 per-pupil components (general current expense, capital outlay, grants & entitlements, food service, local debt service, SDA debt service) that sum to the published total. Header sits on row 3 under a banner; `get_raw_tges()` skips it. Data year comes from the `FY##` token (`Detail_FY24` = end_year 2024), not the report year. |

Internally, CSG1-CSG15 (budget indicators) all share `tidy_generic_budget_indicator()`
and CSG16-CSG19 (personnel) share `tidy_generic_personnel()`; CSG14 is the one
exception (a salary-share fraction, reshaped over its 3-year window).

### Reporting-year layout

TGES tables are wide across multiple report years; the cleaners reshape to long with
an `end_year` per row:

- **Budget indicators (CSG1-15):** 2 actual years (`end_year-2`, `end_year-1`, both
  `calc_type = "Actuals"`) + 1 budgeted year (`end_year`, `calc_type = "Budgeted"`).
- **Personnel (CSG16-19):** 2 years (`end_year-1`, `end_year`).
- **Fund balance (CSG20-21):** 2 years (`end_year-2`, `end_year-1`).
- **Vital statistics (`VITSTAT_TOTAL`):** single year, `end_year-1`.
- 1999-2003 encoded the year inside the variable names; `year_variable_converter()`
  normalizes those to the 2004+ style before reshaping.

### Rank format

Ranks are parsed by `parse_rank()`: a plain integer through ~2015, then
`"rank|out_of"` (e.g. `"33|57"` = 33rd of 57 in the peer group) from 2019 on. **Only
the rank is kept — the peer-group size is discarded.** `"N.R."` (Not Reported) /
`"N.A."` (Not Applicable) / blanks become `NA`.

---

## Entity coverage

TGES is a **district + state/peer-group-average** report. Rows are districts plus
group-average rows (state averages, enrollment-band peer groups). **There is no
school-level (building) data in TGES** — that is a structural property of the source,
not a gap to close. (For school-level spending, the SPR databases are the route; see
`spr-coverage-gap.md`.)

---

## What's left to cover

TGES is **fully covered for every year that exists**. The remaining items are source
limitations, not unbuilt fetchers:

| Item | Status | Notes |
|---|---|---|
| **1999, 2000** | Not retrievable | NJ DOE links these years but the downloads 404 at the source. `tges_url_for_year()` errors for them. Not a code gap — the data isn't available. The DBF-reading path is already in place if they ever reappear. |
| **`SUMMARY` / `SUMYR3-5` / `October####_DRTRS` in 2024/2025 bundles** | Passes through raw, untested | These bundle members still fall through `tidy_tges_data()` un-tidied. `DRTRS` is a transportation **efficiency ratio** (DRTRS Utility), not a dollar cost. If a per-year bundle adds a new table type it returns raw; the structure test (`test-tges-structure.R`) only pins the historical CSG set, so re-audit the member list when adding a new year. (`Detail_FY##` is now covered — see the coverage table.) |
| **Peer-group size (`out_of` in ranks)** | Intentionally dropped | `parse_rank()` keeps only the rank integer. Retaining the denominator would need a schema change. Low demand. |

### When adding a new year

1. Confirm the zip URL/layout in `tges_url_for_year()` (post-2023 years use a
   per-year subfolder with an irregular bundle name — add to `special_urls`).
2. Run `get_raw_tges(<year>)` and diff the returned `names()` against the cleaner
   keys in `tidy_tges_data()`. Any new key passes through raw — add a cleaner or
   confirm it's intentional.
3. Extend the valid-year range in the `tges_url_for_year()` error message and the
   roxygen `@param end_year` docs.
4. Add ground-truth assertions to `test-tges-ground-truth.R` pinning real values.

---

## Comparative-analysis toolkit (`R/tges_analysis.R`)

Nine exported helpers sit on top of `fetch_tges()` / `fetch_many_tges()` and point
the peer-benchmarking engine in `percentile_rank.R` at dollars. All consume a
`fetch_tges()` (single) or `fetch_many_tges()` (nested) object and drop
group-average rows (`district_code` NA / `"00NA"`):

| Function | What it returns |
|---|---|
| `tges_composition()` | one row per district-year, each spending category as per-pupil $ + its share of budgetary per-pupil cost |
| `tges_percentile_rank()` | ranks any TGES metric within a peer group (`tges_group` / `dfg` / `county` / `statewide`) |
| `tges_efficiency()` | joins per-pupil spend to a caller-supplied outcome percentile + labels the spend-vs-outcome quadrant |
| `tges_revenue_mix()` | VITSTAT revenue shares + per-pupil $ attribution (local / state / federal / ...) |
| `tges_fund_balance_health()` | CSG20 + CSG21 joined, with `excess_surplus_flag` and `declining_balance_flag` |
| `tges_federal_exposure()` | ESSER-cliff screen off VITSTAT federal share (baseline vs ESSER-peak bump + spending growth) |
| `tges_staffing()` | CSG16-19 ratios + median salaries + CSG14 benefits share, one row per district-year |
| `tges_red_flags()` | loops the rank wrapper across indicators; surfaces a district's top/bottom-decile placements |
| `tges_real_growth()` | decomposes per-pupil growth (CSG1AA) into real-cost vs enrollment-denominator components |
| `tges_excluded_costs()` | joins `DETAIL_FY##` to CSG1: the 6 spending components excluded from budgetary cost + `excluded_total_pp` / `gce_excess_pp` differences, with a `residual_reliable` flag for the denominator caveat (see Pension coverage below) |

(A further cross-district layer — `tges_find_peers()`, `tges_frontier()`,
`tges_convergence()`, `tges_composition_drift()`, `tges_gap_cost()`,
`tges_volatility()`, `tges_compare()` — sits on top of these; see `_pkgdown.yml`.)

Tested in `tests/testthat/test-tges-analysis.R` (synthetic unit + live). Design
notes and the persona-by-persona product map live in
`research-private/analysis/tges-fiscal-analysis-roadmap.md`.

## Pension / on-behalf TPAF coverage (and why subtraction can't isolate it)

**The question:** can TGES tell us per-district teacher-pension cost? In NJ the
state pays TPAF pension, post-retirement medical (PRM), and the employer share of
social security **on behalf of districts** — by law these never hit a district's
own budget. So they are excluded from the headline **Budgetary Per Pupil Cost**
(CSG1) and from CSG2-15. They *are* folded into **Total Spending Per Pupil**
(CSG1AA / VITSTAT), but only lumped with eight other excluded categories.

**Per NJDOE's 2025 guide, Total Spending minus Budgetary cost spans nine
categories:** (1) on-behalf TPAF pension + PRM + social security, (2)
transportation, (3) judgments, (4) food service, (5) capital outlay, (6) special
revenues / grants (preschool, IDEA, Title I), (7) tuition to other districts, (8)
local debt service, (9) SDA construction debt service. Pension is one slice.

**What the public files let us peel off.** The `Detail_FY##` workbook itemizes
capital outlay, grants & entitlements, food service, and both debt-service lines
per district. That leaves the on-behalf TPAF buried inside **General Current
Expense** alongside transportation, tuition, and judgments. `tges_excluded_costs()`
computes `gce_excess_pp = general_current_expense_pp − budgetary_pp` as the
narrowest residual we can reach (≈ transportation + on-behalf TPAF + tuition +
judgments). **It is an upper bound on pension, not a measurement.**

**Two reasons subtraction can't get to clean pension:**
1. *No itemization.* Neither the `Detail_FY##` file, the TGES bundle, nor the
   NJDOE per-district State Aid file (`FY##_GBM_District_Details.xlsx`) breaks out
   the TPAF lines. The State Aid file line-items Transportation **Aid** (a
   formula subsidy, not cost) and has no pension column. The TGES transportation
   members (`Website efficiency.xlsx`, `October####_DRTRS.xlsx`) are a DRTRS
   **efficiency ratio**, not dollars — so transportation cost can't be netted out
   either.
2. *Denominator mismatch.* Budgetary cost divides by **resident enrollment**;
   the Detail per-pupil figures divide by **enrollment + sent pupils**. For
   self-contained districts these agree within ~1%, but for sending districts
   (including big cities placing special-ed / vocational pupils out, e.g. Newark
   ~9%, Jersey City ~8%) the per-pupil subtraction is invalid. Hence
   `sent_pupil_share` + `residual_reliable` (default threshold 2%); ~40% of
   districts fail it.

**The only clean source is AudSum.** NJDOE's Audit Summary (the audited financial
filing every district submits, and the source data behind TGES) carries on-behalf
TPAF pension/PRM/SS as explicit GASB on-behalf revenue **and** expenditure lines,
district-keyed. But AudSum is login-gated behind the Homeroom portal with **no
public bulk download**. Getting itemized per-district pension would require an
OPRA request or a data-desk ask (`audsum@doe.nj.gov`). Fund-level TPAF health
(funded ratio, UAAL, employer contribution) is public at
`nj.gov/treasury/pensions/actuarial-valuations.shtml` but is not district-allocable.

> Bottom line: `tges_excluded_costs()` is the honest ceiling reachable from public
> data. Treat `gce_excess_pp` as "transportation + pension + tuition," reliable
> only for self-contained districts, never as pension alone. Clean per-district
> pension needs an AudSum data request.

## Related

- `R/tges.R` — all TGES fetch/tidy code; `R/tges_analysis.R` — the comparative toolkit above.
- `tests/testthat/` — `test-fetch-tges.R`, `test-tges-ground-truth.R`,
  `test-tges-structure.R`, `test-tges-url.R`, `test-tges-parse-rank.R`,
  `test-tges-analysis.R`, `helper-tges.R`.
- `dev-docs/data-source-urls.md` — load when a fetch URL 404s or needs a new-year update.
- Vignettes: `somsd-school-spending.Rmd`, `newark-school-spending.Rmd` — full
  deep-dives built on `fetch_tges()`; `newark-fiscal-brief.Rmd` — Newark vs. DFG A
  comparative brief exercising the toolkit above.
