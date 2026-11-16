# Fetch Dropout Rate Data

Downloads dropout rate trends from SPR database.

## Usage

``` r
fetch_dropout_rates(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2025)

- level:

  One of "school" or "district"

## Value

Data frame with dropout rates

The 2017 school_rate and state_rate labels are harmonized to the
corresponding dropout entity and state rate fields. school_year is
filtered to the requested year and then removed.

## Examples

``` r
if (FALSE) { # \dontrun{
dropout <- fetch_dropout_rates(2024)
} # }
```
