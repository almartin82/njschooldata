# Fetch multiple years of enrollment data with progress

Fetch multiple years of enrollment data with progress

## Usage

``` r
fetch_enr_years(years, tidy = TRUE, allow_partial = FALSE)
```

## Arguments

- years:

  Vector of years to fetch

- tidy:

  Return tidy format? (default TRUE)

- allow_partial:

  If \`TRUE\`, return successful years and attach status for
  missing/failed years. The default is strict.

## Value

Data frame with all enrollment data and per-year source status.

## Examples

``` r
if (FALSE) { # \dontrun{
enr_5yr <- fetch_enr_years(2020:2024)
} # }
```
