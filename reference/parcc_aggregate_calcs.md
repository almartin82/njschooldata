# Aggregate multiple PARCC rows and produce summary statistics

Aggregate multiple PARCC rows and produce summary statistics

## Usage

``` r
parcc_aggregate_calcs(df)
```

## Arguments

- df:

  grouped df of PARCC data

## Value

df with aggregate stats for whatever grouping was provided. In addition
to the rolled-up counts and recomputed percentages, the output records
provenance of each aggregate row:

- districts:

  collapsed list of the district names rolled up

- schools:

  collapsed list of the school names rolled up

- tests:

  collapsed list of the test(s) (`test_name`, e.g.
  "math"/"ela"/"science") rolled into the row, so callers can see which
  assessment(s) an aggregate combines (issue \#98)

- n_schools:

  number of distinct schools contributing to the row. Uses
  `n_distinct(school_name)` because the grouped input holds one row per
  (school, grade/course) – e.g. a 3-8 school appears as six rows – so
  [`n()`](https://dplyr.tidyverse.org/reference/context.html) would
  overcount. (issue \#70)

- n_charter_rows:

  number of input rows flagged `is_charter`
