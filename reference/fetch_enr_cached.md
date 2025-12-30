# Fetch enrollment data with caching

This is a cached wrapper around
[`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md).
On the first call with a given set of parameters, data is downloaded
from NJ DOE. Subsequent calls with the same parameters return cached
data instantly.

## Usage

``` r
fetch_enr_cached(end_year, tidy = FALSE)
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

## Value

Enrollment data frame (from cache if available)

## See also

[`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md),
[`njsd_cache_info`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# First call downloads data
enr <- fetch_enr_cached(2024)

# Second call returns cached data
enr <- fetch_enr_cached(2024)  # Instant!

# Check cache status
njsd_cache_info()
} # }
```
