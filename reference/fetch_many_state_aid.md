# Fetch Multiple Years of NJ K-12 State Aid

Fetch Multiple Years of NJ K-12 State Aid

## Usage

``` r
fetch_many_state_aid(end_year_vector, allow_partial = FALSE)
```

## Arguments

- end_year_vector:

  vector of school years (end of the academic year). Valid values come
  from the authoritative source registry.

- allow_partial:

  Return successful years when one request fails. The default is strict.
  In either mode, inspect
  [`get_source_results()`](https://almartin82.github.io/njschooldata/reference/get_source_results.md)
  for the status of every requested year.

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
  filter(district_id == "3570", aid_category == "transportation_aid") %>%
  select(end_year, amount)
} # }
```
