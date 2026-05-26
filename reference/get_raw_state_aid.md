# Get Raw NJ State Aid District Details

Downloads one year of the NJ DOE K-12 State Aid "District Details"
workbook. Tries the current-year direct URL first, then falls back to
the archived per-year zip bundle and locates the district-details member
by name.

## Usage

``` r
get_raw_state_aid(end_year)
```

## Arguments

- end_year:

  school year (end of the academic year): the 2025-26 year (state
  FY2026) is `end_year = 2026`. Valid values are 2019 and later; earlier
  years use a different layout that this fetcher does not yet parse.

## Value

a wide data frame (one row per district), header detected at the first
row carrying both "County" and "Dist"
