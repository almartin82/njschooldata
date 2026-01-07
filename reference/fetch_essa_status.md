# Fetch ESSA Accountability Status

Downloads ESSA accountability ratings from SPR database.

## Usage

``` r
fetch_essa_status(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with ESSA status ratings

## Examples

``` r
if (FALSE) { # \dontrun{
essa <- fetch_essa_status(2024)
} # }
```
