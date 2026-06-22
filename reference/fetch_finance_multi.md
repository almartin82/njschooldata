# Fetch multiple years of NJ school finance

Fetch multiple years of NJ school finance

## Usage

``` r
fetch_finance_multi(
  end_year_vector = NULL,
  end_years = NULL,
  tidy = TRUE,
  use_cache = TRUE
)
```

## Arguments

- end_year_vector:

  vector of school years (end of the academic year). See
  [`get_available_finance_years`](https://almartin82.github.io/njschooldata/reference/get_available_finance_years.md)
  for valid values.

- end_years:

  alias for `end_year_vector`, used by cross-state discovery tooling.

- tidy:

  logical, default `TRUE`. See
  [`fetch_finance`](https://almartin82.github.io/njschooldata/reference/fetch_finance.md).

- use_cache:

  logical, default `TRUE`. See
  [`fetch_finance`](https://almartin82.github.io/njschooldata/reference/fetch_finance.md).

## Value

A single tibble, the per-year results of
[`fetch_finance`](https://almartin82.github.io/njschooldata/reference/fetch_finance.md)
stacked.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Statewide per-pupil total over time
fetch_finance_multi(2018:2024) %>%
  filter(is_state, metric == "per_pupil_total") %>%
  select(end_year, value)
} # }
```
