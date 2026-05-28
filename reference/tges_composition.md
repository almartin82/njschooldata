# Build a per-pupil spending composition table

Reshapes the per-category TGES indicator tables into one row per
district-year with each major spending category as a per-pupil-dollar
column, plus that category's share of the budgetary per-pupil cost. This
is the backbone for "dollars to the classroom" and composition-drift
analysis.

Categories are pulled by table code (robust to label changes):

- `budgetary_pp` (CSG1) – budgetary per-pupil cost (the share
  denominator)

- `classroom` (CSG2), `support_services` (CSG6), `administration`
  (CSG8), `plant_ops` (CSG10), `food_service` (CSG12), `extracurricular`
  (CSG13), `equipment` (CSG15)

- `total_pp` (CSG1AA) – total per-pupil expenditures, if available

Shares are each category divided by `budgetary_pp`. They are not
guaranteed to sum to 1: the categories are the standard TGES reporting
buckets, not a strict partition, and some (food, extracurricular) sit
outside the budgetary per-pupil definition.

## Usage

``` r
tges_composition(tges, years = NULL, calc_type = NULL)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  (one year) or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
  (several years).

- years:

  Optional numeric vector. Keep only these `end_year` values.

- calc_type:

  Optional character. Keep only this calc type, e.g. `"Actuals"` or
  `"Budgeted"`.

## Value

A tibble with entity columns (`county_name`, `district_id`,
`district_name`, `group`), `end_year`, `calc_type`, the per-pupil
category columns, and the matching `*_share` columns.

## Examples

``` r
if (FALSE) { # \dontrun{
# One year
comp <- tges_composition(fetch_tges(2024))

# Classroom share for Newark, actuals only
library(dplyr)
tges_composition(fetch_many_tges(2020:2024), calc_type = "Actuals") %>%
  filter(district_id == "3570") %>%
  select(end_year, classroom, budgetary_pp, classroom_share)

# Lowest classroom-share districts in 2024
tges_composition(fetch_tges(2024), calc_type = "Budgeted") %>%
  arrange(classroom_share) %>%
  select(district_name, classroom_share, administration_share) %>%
  head(10)
} # }
```
