# NJ Finance — Phase 1 Source Verification

**Date verified:** 2026-06-10
**Verdict:** SHIPPED (real NJ DOE sources, both per-pupil spending and state-aid revenue)

NJ already had two finance pipelines (`R/tges.R` and `R/state_aid.R`). Phase 1
re-verified both live before wiring the uniform `fetch_finance()` front door.

## Sources (all HTTP 200, real files)

| Source | URL pattern | Format | Coverage | Provides |
|--------|-------------|--------|----------|----------|
| Taxpayers' Guide to Educational Spending (TGES/CSG) | `https://www.nj.gov/education/guide/docs/{year}_TGES.zip` (2011-2023); `.../docs/{year}/TGES{yy}_Zipped.zip` (2024+); `.../{year}_CSG.zip` (2001-2010) | zip of CSV/XLSX/DBF | 2001-2025 reports | Per-pupil total + category spending (actuals), ADE denominator, statewide average |
| Governor's Budget Message — District Details (state aid) | `https://www.nj.gov/education/stateaid/{code}/FY{yy}_GBM_District_Details.xlsx`; archive `.../stateaid/zippedfiles/{code}.zip` | xlsx (in zip for prior years) | FY2019+ | Total K-12 state aid + categories per district, statewide total |

Live checks on 2026-06-10 (all `HTTP/2 200`):
- `TGES2025_Zipped.zip` — 889,011 bytes, `application/zip`
- `2023_TGES.zip` — 871,679 bytes
- `FY26_GBM_District_Details.xlsx` — 77,477 bytes, `...spreadsheetml.sheet`
- `stateaid/zippedfiles/2425.zip` — 1,088,273 bytes

## FY <-> SY mapping

`end_year` = fiscal/school year END. FY2024 = SY 2023-24. NJ publishes a data
year's spending ACTUALS in the guide released the FOLLOWING year (FY2024 actuals
appear in the 2025 guide), so `fetch_finance()` fetches `fetch_tges(end_year + 1)`
for the spending side and keeps `calc_type == "Actuals"`. State aid is
appropriated for the named year, read directly from `fetch_state_aid(end_year)`.

## Metric mapping (NJ → canonical vocabulary)

| Canonical metric | NJ source | Notes |
|------------------|-----------|-------|
| `per_pupil_total` | TGES `CSG1AA_AVGS` "Per Pupil Total Expenditures" | denominator = ADE + sent pupils; carries statewide-average row |
| `per_pupil_instruction` | TGES `CSG2` | classroom instruction per pupil |
| `per_pupil_support_services` | TGES `CSG6` | NJ-specific (per-pupil, not absolute) |
| `per_pupil_administration` | TGES `CSG8` | NJ-specific |
| `per_pupil_operations_maintenance` | TGES `CSG10` | NJ-specific |
| `per_pupil_food_service` | TGES `CSG12` | NJ-specific |
| `revenue_state` | state aid `fy_NN_k_12_aid` total | absolute dollars; carries statewide total row |

## Year coverage of `fetch_finance()`

- Spending (TGES actuals): 2001-2024
- Revenue (state aid): 2019-2026
- Years 2025+ → `revenue_state` only; pre-2019 → per-pupil spending only.

## Traps / caveats

- **Spending is published a year in arrears** — the +1 guide mapping is essential;
  the latest full per-pupil cross-section is FY2024 (2025 guide).
- **CSG2 vs CSG1AA denominator mismatch** — instruction per-pupil (CSG2) uses
  resident enrollment while total (CSG1AA) uses ADE + sent pupils. For charters and
  heavy sending/receiving districts the two diverge so an instruction-as-share-of-
  total ratio can exceed 1. Do NOT present that ratio as clean; the vignette uses
  state-aid concentration instead.
- **Source row duplication** — the NJ DOE file occasionally repeats a district's
  row verbatim (observed: charter `7021` in the 2025 CSG1AA). `fetch_finance()`
  collapses EXACT duplicates with `distinct()`; genuinely conflicting values would
  survive and be caught by the dedup test (never silently averaged/fabricated).
- **NCES linkage** — NJ `district_id` is unique statewide (648/648 in the bundled
  crosswalk), so the join is `district_id → nces_dist` directly (~94% district
  match). `nces_sch` always NA (NJ finance is district-level only). Unmatched stays NA.
