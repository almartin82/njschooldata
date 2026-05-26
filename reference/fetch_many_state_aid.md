# Fetch Multiple Years of NJ K-12 State Aid

Fetch Multiple Years of NJ K-12 State Aid

## Usage

``` r
fetch_many_state_aid(end_year_vector)
```

## Arguments

- end_year_vector:

  vector of school years (end of the academic year). Valid values are
  2019 and later.

## Value

A single tibble, the per-year results of
[`fetch_state_aid`](https://almartin82.github.io/njschooldata/reference/fetch_state_aid.md)
stacked (one row per district per category per year).

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Transportation aid trend for one district across years
fetch_many_state_aid(2022:2026) %>%
  filter(district_code == "3570", aid_category == "transportation_aid") %>%
  select(end_year, amount)
} # }
```
