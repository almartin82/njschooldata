# Fetch Dropout Rate Data

Downloads dropout rate trends from SPR database.

## Usage

``` r
fetch_dropout_rates(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with dropout rates

## Examples

``` r
if (FALSE) { # \dontrun{
dropout <- fetch_dropout_rates(2024)
} # }
```
