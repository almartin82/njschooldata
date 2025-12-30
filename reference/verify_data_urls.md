# Verify all configured URLs for a data type

Checks that URLs for a range of years are accessible.

## Usage

``` r
verify_data_urls(data_type, years = NULL)
```

## Arguments

- data_type:

  One of "enrollment", "graduation", "assessment"

- years:

  Vector of years to check (defaults to recent 3 years)

## Value

Data frame with URL, year, and accessibility status

## Examples

``` r
if (FALSE) { # \dontrun{
verify_data_urls("enrollment", 2022:2024)
} # }
```
