# SPED Phase 1 Findings (NJ DOE IDEA Section 618)

Source-discovery notes for the special-education pipeline. Captured 2026-06-13.

## Sources (all NJ DOE, verified live 2026-06-13)

NJ DOE publishes IDEA Section 618 public reporting under
`https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/`.
Two collections are wired up:

1. **Classification rate** (`fetch_sped()`) — count of students with IEPs and
   the general-education enrollment denominator. District-level for 2024-2025;
   statewide child count by disability category for 2025+.
2. **Educational environment / placement (LRE)** (`fetch_sped_placement()`) —
   placement settings by disability, race, gender, LEP; state + district; ages
   3-5 and 5-21; 2020-2025. (Already shipped in PRs #278/#279.)

## TRAP: 2025 broke the classification-rate filename + structure convention

The pre-2025 classification workbook lived in a **prior-year-labeled** folder
with a stable name:

```
docs/2023_618data/DistrictWide_ClassificationRate_2324_public.xlsx   (end_year 2024, HTTP 200)
```

`build_sped_url()` extrapolated this pattern to 2025 and produced a **404**:

```
docs/2024_618data/DistrictWide_ClassificationRate_2425_public.xlsx   (404 — does not exist)
```

For SY2024-25 NJ DOE switched to the **consolidated IDEA-618 public reporting**
naming, in the **current-year-labeled** folder:

```
docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx   (HTTP 200)
```

This single workbook also changed shape: instead of one flat sheet it now has
**two sheets**, each with the column-header row at **row 5** (`skip = 4`):

- **"District Rates"** — `County Code | County Name | District Code |
  District Name | Total Enrollment | Count of Student with IEPs |
  District Classification Rate`. Maps onto the existing `fetch_sped()` schema.
  Includes embedded `Statewide Total` (county_id `99`) and `Charters`
  (county_id `80`) rows, plus an `end of worksheet` sentinel.
- **"State Rates"** — `Disability Category | Count of Student with IEPs |
  Classification Rate`. **This is the canonical child-count-by-disability
  table** the cross-state spec asks for, and is NEW in 2025 (earlier years
  404 for any state-by-disability file). The classification rate is a
  **decimal** here (0.0227 = 2.27%), unlike the District Rates sheet which uses
  whole percents (18.03). The 13 disability categories sum **exactly** to the
  `Statewide Total` rollup (242,001 for 2025), so fidelity reconciles cleanly.

### Fix shipped
- `build_sped_url()` switches to the consolidated name for `end_year >= 2025`.
- `get_raw_sped(end_year, level)` reads the correct sheet (`District Rates` /
  `State Rates`) with `skip = 4` for 2025+, keeping the pre-2025 single-sheet
  path (`skip = 3`) unchanged.
- `clean_sped_df()` now coerces value columns to numeric (the 2025 sheet reads
  counts/rates as character because of the trailing sentinel row).
- New `level = "state"` path on `fetch_sped()` returns child count by
  standardized `disability_category` (reusing
  `standardize_sped_placement_subgroups()`; `Statewide Total` → `all_disabilities`).

### Generalizable lesson
NJ DOE's IDEA-618 folder labels flip between **prior-year** (pre-2025) and
**current-year** (2025+) conventions, and the 2025 "consolidated public
reporting" rename (`<year>IDEA618PublicReporting_*`) breaks any
filename-extrapolation logic. When a SPED fetch 404s for a new year, check the
`<end_year>_618data/<end_year>IDEA618PublicReporting_*.xlsx` consolidated
naming, expect a multi-sheet workbook with header rows pushed down to row 5,
and watch for decimal-vs-whole-percent rate encoding differing per sheet.

## Standardized disability categories (NJ → cross-state)

NJ uses `Auditory Impairment` (not "hearing impairment"/"deafness") and
`Emotional Regulation Impairment` (renamed from "Emotional Disturbance"); both
are preserved as `auditory_impairment` / `emotional_regulation_impairment`.
`Preschool Child with a Disability` → `preschool_disability`. The full mapping
lives in `standardize_sped_placement_subgroups()` in `R/sped_placement.R`.
