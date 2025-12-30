# Fetch multiple years of enrollment data with progress

Fetch multiple years of enrollment data with progress

## Usage

``` r
fetch_enr_years(years, tidy = TRUE)
```

## Arguments

- years:

  Vector of years to fetch

- tidy:

  Return tidy format? (default TRUE)

## Value

Data frame with all enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
enr_5yr <- fetch_enr_years(2020:2024)
} # }
```
