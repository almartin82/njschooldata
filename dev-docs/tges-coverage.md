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
| **Unknown tables in 2024/2025 bundles** | Passes through raw, untested | If the per-year bundle zips ever add a new table type, `tidy_tges_data()` returns it un-tidied (cleaner lookup falls through). The structure test (`test-tges-structure.R`) only pins the historical CSG set, so a new sheet would not fail loudly. This is the one untested edge — re-audit the member list when adding a new year. |
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

Tested in `tests/testthat/test-tges-analysis.R` (synthetic unit + live). Design
notes and the persona-by-persona product map live in
`research-private/analysis/tges-fiscal-analysis-roadmap.md`.

## Related

- `R/tges.R` — all TGES fetch/tidy code; `R/tges_analysis.R` — the comparative toolkit above.
- `tests/testthat/` — `test-fetch-tges.R`, `test-tges-ground-truth.R`,
  `test-tges-structure.R`, `test-tges-url.R`, `test-tges-parse-rank.R`,
  `test-tges-analysis.R`, `helper-tges.R`.
- `dev-docs/data-source-urls.md` — load when a fetch URL 404s or needs a new-year update.
- Vignettes: `somsd-school-spending.Rmd`, `newark-school-spending.Rmd` — full
  deep-dives built on `fetch_tges()`; `newark-fiscal-brief.Rmd` — Newark vs. DFG A
  comparative brief exercising the toolkit above.
