# Fetch NJ SPED placement data for multiple years

Convenience wrapper that calls
[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)
for each year and binds the results. Strict mode is the default; partial
results must be requested explicitly and retain per-year source status.

## Usage

``` r
fetch_sped_placement_multi(
  end_years,
  age_group = "5-21",
  level = "district",
  tidy = TRUE,
  with_status = FALSE,
  allow_partial = FALSE
)
```

## Arguments

- end_years:

  integer vector of school years

- age_group:

  one of `"5-21"` or `"3-5"`

- level:

  one of `"district"` or `"state"`

- tidy:

  logical; passed through to
  [`fetch_sped_placement()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)

- with_status:

  logical; passed through to
  [`fetch_sped_placement()`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)

- allow_partial:

  logical; if `FALSE` (default), any failed or unsupported year aborts
  the request. If `TRUE`, successful years are returned with status
  available from
  [`get_source_results()`](https://almartin82.github.io/njschooldata/reference/get_source_results.md).

## Value

A single tibble with source-result provenance.

## Details

Every `(end_year, age_group, level)` combination across 2020-2025
returns data, so `fetch_sped_placement_multi(2020:2025)` produces a
single bound tibble covering the whole range. A per-year failure aborts
in strict mode; partial results require `allow_partial = TRUE`.

## See also

[`fetch_sped_placement`](https://almartin82.github.io/njschooldata/reference/fetch_sped_placement.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Pull every supported year (district 5-21) into one tibble.
placement_all <- fetch_sped_placement_multi(2020:2025)

# Full state-level coverage across 2020-2025 (combines structured
# downloads with transcribed-PDF slices for state-level 2020-2022).
fetch_sped_placement_multi(2020:2025, level = "state")
} # }
```
