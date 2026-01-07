# Fetch Staff Demographics Data

Downloads teacher/administrator demographic data from SPR database.

## Usage

``` r
fetch_staff_demographics(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with staff race/gender breakdowns

## Examples

``` r
if (FALSE) { # \dontrun{
staff <- fetch_staff_demographics(2024)
} # }
```
