# Finance Data Spec

`fetch_finance()` is the canonical finance front door for this package. It
normalizes NJ DOE district finance sources onto one long `metric`/`value`
schema while preserving source values exactly as published.

## Sources

| Source | Coverage | Provides |
| --- | --- | --- |
| Taxpayers' Guide to Educational Spending (TGES/CSG) | 2001-2025 reports | Per-pupil spending actuals, including statewide average for total per-pupil spending |
| Governor's Budget Message District Details | FY2019+ | Total K-12 state aid by district and statewide total |

No finance value is sourced from a federal data source. Federal identifiers are
used only as optional join keys through the bundled NCES crosswalk.

## Year Convention

`end_year` is the fiscal/school year END. `end_year = 2024` is FY2024 and school
year 2023-24.

TGES publishes spending actuals in the guide released the following year:
FY2024 actuals appear in the 2025 guide. `fetch_finance(2024)` therefore reads
`fetch_tges(2025)` and keeps `calc_type == "Actuals"`.

State aid is already keyed to the named fiscal/school END year, so
`fetch_finance(2024)` reads `fetch_state_aid(2024)`.

The finance front door validates this alignment before combining spending and
revenue rows so a one-year drift fails loudly.

## Canonical Columns

Default output columns, in order:

| Column | Meaning |
| --- | --- |
| `end_year` | Fiscal/school year END |
| `state_id` | Four-digit NJ district code; `NA` for statewide rows |
| `entity_name` | District name or `New Jersey` for statewide rows |
| `county` | County name for district rows |
| `is_state` | Statewide aggregate row |
| `is_district` | District row |
| `is_school` | Always `FALSE` in this fetcher |
| `is_charter` | `NA`; source files do not publish a charter flag |
| `nces_dist` | Optional district NCES identifier from the bundled crosswalk |
| `nces_sch` | Always `NA`; this fetcher is not school-level |
| `metric` | Canonical finance metric |
| `value` | Published nominal dollar value |
| `is_per_pupil` | `TRUE` for `per_pupil_*`, `FALSE` for `revenue_*` |
| `enrollment_denominator` | Published denominator where TGES carries it |

When `with_status = TRUE`, `value_status` is appended after these columns.

## Metrics

| Metric | Source | Notes |
| --- | --- | --- |
| `per_pupil_total` | TGES `CSG1AA_AVGS` | Total per-pupil expenditures; carries statewide average and ADE plus sent pupils denominator |
| `per_pupil_instruction` | TGES `CSG2` | Classroom instruction per pupil |
| `per_pupil_support_services` | TGES `CSG6` | NJ-specific per-pupil category |
| `per_pupil_administration` | TGES `CSG8` | NJ-specific per-pupil category |
| `per_pupil_operations_maintenance` | TGES `CSG10` | NJ-specific per-pupil category |
| `per_pupil_food_service` | TGES `CSG12` | NJ-specific per-pupil category |
| `revenue_state` | State aid `fy_NN_k_12_aid` | Total K-12 state aid, absolute dollars |

All finance metrics are registered in `inst/extdata/metric_registry.csv` with
`unit = dollars`, `polarity = neutral`, `is_rate = FALSE`, and blank
`denominator_metric`. The per-pupil metrics are already dollar amounts per
pupil, not rates in the registry sense.

## Entity Grain

The default `level = "all"` returns state and district rows. `level = "state"`
and `level = "district"` filter to those grains.

NJ finance in this front door is district/state only. School-level per-pupil
expenditure reporting exists as a separate NJ DOE source, but it is not wired
into `fetch_finance()`. `level = "school"` returns structural gap rows with
`is_school = FALSE` and missing values; with `with_status = TRUE`, those rows
carry `value_status = "not_published"`.

## Status And Missingness

Finance missingness is structural, not raw-token suppression:

| Condition | `value_status` |
| --- | --- |
| Published numeric value | `actual` |
| Current per-pupil actuals not yet published | `not_yet_observed` |
| Structural school-level gap or absent denominator on a missing per-pupil row | `not_published` |

Suppressed cells are not back-derived from percentages or totals.

## Subgroups

Finance has no subgroup dimension. There is no `subgroup` column and therefore
no `subgroup_std` column to add.

## Coverage

- Per-pupil spending actuals: `end_year` 2001-2024.
- State-aid revenue: `end_year` 2019-2026.
- Years 2025+ return `revenue_state` by default. With `with_status = TRUE`, the
  unobserved per-pupil metrics are also represented as `not_yet_observed`.
