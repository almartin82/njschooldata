# Calculate Discipline Rates by Subgroup

Calculates discipline rates by subgroup for disproportionality analysis.
Computes rates per specified base (default 1000 students) and calculates
risk ratios compared to total population.

## Usage

``` r
calc_discipline_rates_by_subgroup(df, rate_per = 1000, by_grade = FALSE)
```

## Arguments

- df:

  A data frame from
  [`fetch_disciplinary_removals`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md),
  [`fetch_violence_vandalism_hib`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md),
  [`fetch_police_notifications_detail`](https://almartin82.github.io/njschooldata/reference/fetch_police_notifications_detail.md),
  [`fetch_arrests`](https://almartin82.github.io/njschooldata/reference/fetch_arrests.md),
  or similar discipline data. Must contain subgroup column and a
  count/number column.

- rate_per:

  Base for rate calculation (default: 1000). For example, rate_per =
  1000 calculates incidents per 1000 students.

- by_grade:

  Logical, default `FALSE`. When `TRUE` and the input carries a
  `grade_level` column, `grade_level` is added to the per-entity
  grouping keys so rates and risk ratios are computed within each
  (entity \\\times\\ grade) cell. When `TRUE` but the input has no
  `grade_level` column, the function warns and falls through to the flat
  (per-subgroup) calculation. When `FALSE` (default) the calculation
  matches the pre-existing behavior even when a `grade_level` column is
  present (grade rows do not contaminate the subgroup-marginal
  risk-ratio denominator).

## Value

Data frame with discipline rates including:

- All original columns from input data

- discipline_rate - Incidents per rate_per students

- percent_by_subgroup - Percentage of total incidents by subgroup

- risk_ratio - Ratio of subgroup rate to total population rate (values
  \> 1 indicate higher risk than total population)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get disciplinary removals data
discipline <- fetch_disciplinary_removals(2024)

# Calculate rates per 1000 students
rates <- calc_discipline_rates_by_subgroup(discipline, rate_per = 1000)

# View disproportionality for racial subgroups
rates %>%
  dplyr::filter(subgroup %in% c("black", "hispanic", "white")) %>%
  dplyr::select(school_name, subgroup, discipline_rate, risk_ratio)

# Grade-level disproportionality on the SPR Group/Grade detail sheets
arrests <- fetch_arrests(2025, level = "district")
grade_rates <- calc_discipline_rates_by_subgroup(arrests, by_grade = TRUE)
grade_rates %>%
  dplyr::filter(is_state, grade_level != "TOTAL") %>%
  dplyr::select(grade_level, subgroup, discipline_rate, risk_ratio)
} # }
```
