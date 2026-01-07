# Fetch Student-Staff Ratio Data

Downloads student-to-staff ratio data from SPR database.

## Usage

``` r
fetch_staff_ratios(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with staff ratios

## Examples

``` r
if (FALSE) { # \dontrun{
ratios <- fetch_staff_ratios(2024)
} # }
```
