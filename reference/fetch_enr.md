# Gets and processes a NJ enrollment file

\`fetch_enr\` is a wrapper around \`get_raw_enr\` and \`process_enr\`
that downloads and cleans enrollment data for a given year.

## Usage

``` r
fetch_enr(end_year, tidy = FALSE, use_cache = FALSE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2006-07
  school year is year '2007'. Valid values are 2000-2025.

- tidy:

  If TRUE, takes the unwieldy wide data and normalizes into a long, tidy
  data frame with limited headers - constants (school/district name and
  code), subgroup (all the enrollment file subgroups), program/grade and
  measure (row_total, free lunch, etc).

- use_cache:

  If TRUE, uses the session cache to avoid re-downloading data. See
  [`njsd_cache_info`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md)
  for cache details.

## Value

Data frame with processed enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2023 enrollment data
enr_2023 <- fetch_enr(2023)

# Get tidy (long format) enrollment data
enr_tidy <- fetch_enr(2023, tidy = TRUE)

# Use caching for faster repeat calls
enr_cached <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
} # }
```
