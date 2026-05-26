# A side-by-side fiscal scorecard for a named set of districts

The "counterfactual cities" table: line up several districts on the
headline fiscal metrics in one frame. It assembles the per-pupil totals
and composition shares, the revenue mix, the staffing ratios and
salaries, and the excess-surplus flag, one row per district, so
different reform strategies and cost structures sit next to each other.

## Usage

``` r
tges_compare(tges, district_codes, year = NULL, calc_type = "Budgeted")
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- district_codes:

  Character vector of 4-digit district codes to compare.

- year:

  Numeric. Preferred report year. Default: latest composition year.

- calc_type:

  Character. Composition calc type. Default `"Budgeted"`.

## Value

A tibble, one row per requested district, with entity columns and the
headline metrics (`total_pp`, `budgetary_pp`, `classroom_share`,
`administration_share`, `local_share`, `state_share`, `federal_share`,
`student_teacher_ratio`, `student_admin_ratio`, `teacher_salary`,
`benefits_pct_salary`, `excess_surplus_flag`) plus `comp_year`,
`revenue_year`, `staffing_year`.

## Details

This is assembly over the existing primitives
([`tges_composition()`](https://almartin82.github.io/njschooldata/reference/tges_composition.md),
[`tges_revenue_mix()`](https://almartin82.github.io/njschooldata/reference/tges_revenue_mix.md),
[`tges_staffing()`](https://almartin82.github.io/njschooldata/reference/tges_staffing.md),
[`tges_fund_balance_health()`](https://almartin82.github.io/njschooldata/reference/tges_fund_balance_health.md)).
Each metric is pulled at `year` when a row for that year exists,
otherwise at that source's latest available year for the district
(revenue and personnel tables report a different year than the budgeted
composition, so strict year-alignment would blank most cells). The
`*_year` columns record which year each block came from.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

big_cities <- c("3570", "0680", "5210", "4010", "2330", "1330")  # Newark, Camden, ...
tges_compare(fetch_tges(2024), district_codes = big_cities) %>%
  select(district_name, total_pp, classroom_share, local_share,
         student_admin_ratio, excess_surplus_flag)
} # }
```
