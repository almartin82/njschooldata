# Locate the FederalGraduationRates columns for one cohort length

Resolves the entity/state rate columns (and, in 2025, the cohort label
column) for an N-year cohort across the two FederalGraduationRates
layouts: the SY2024-25 redesign (`x_<n>_yr_graduation_rate_federal_*`)
and the pre-redesign layout that embeds the cohort year in the column
name (`x_<yyyy>_<n>_year_federal_graduation_rate` /
`state_<yyyy>_<n>_year_...`).

## Usage

``` r
fed_grad_cols_for_n(nms, n)
```

## Arguments

- nms:

  Character vector of (snake_cased) column names.

- n:

  Cohort length: 4, 5, or 6.

## Value

A list describing the columns, or `NULL` if this cohort length is absent
from the sheet (e.g. the 6-year cohort before SY2023-24).
