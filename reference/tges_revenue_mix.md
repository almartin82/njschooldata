# Decompose where a district's school dollars come from

Reshapes the VITSTAT revenue shares into one row per district-year with
each revenue source as both a share (0-1, as the source reports it) and
a per-pupil-dollar attribution (the share times total spending per
pupil). This is the taxpayer's whole question in one table: how much of
this budget is local property tax versus state aid versus one-time
federal money.

VITSTAT is a single-year table (it reports `end_year - 1` for a given
guide), so pass
[`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md)
output to build a revenue-mix series across years.

## Usage

``` r
tges_revenue_mix(tges, years = NULL)
```

## Arguments

- tges:

  Output of
  [`fetch_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md)
  or
  [`fetch_many_tges()`](https://almartin82.github.io/njschooldata/reference/fetch_many_tges.md).

- years:

  Optional numeric vector. Keep only these `end_year` values.

## Value

A tibble with entity columns, `end_year`, `total_pp`, the `*_share`
columns (local, state, federal, tuition, free_balance, other), and the
matching `*_pp` per-pupil dollar columns.

## Details

Shares are NJ DOE's reported fractions and are not guaranteed to sum to
exactly 1 (rounding). The per-pupil dollar columns (`local_pp`,
`state_pp`, ...) are `total_pp` multiplied by each share, so they carry
the same rounding. `total_pp` is VITSTAT's "Total Spending Per Pupil",
which equals the CSG1AA per-pupil total expenditure for that year.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Newark: what share is local property tax?
tges_revenue_mix(fetch_tges(2024)) %>%
  filter(district_code == "3570") %>%
  select(end_year, total_pp, local_share, state_share, federal_share)

# The most local-tax-dependent districts in the latest year
tges_revenue_mix(fetch_tges(2024)) %>%
  arrange(desc(local_share)) %>%
  select(district_name, local_share, local_pp) %>%
  head(10)
} # }
```
