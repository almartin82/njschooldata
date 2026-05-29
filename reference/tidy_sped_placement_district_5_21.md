# Tidy the District by Ed Environ sheet (school-age, 5-21)

Pivots the wide workbook to long format: one row per (county_id,
district_id, subgroup, environment), with `count` and `percent` columns.
Adds standard entity flags.

## Usage

``` r
tidy_sped_placement_district_5_21(df)
```

## Arguments

- df:

  raw tibble from
  `get_raw_sped_placement(level = "district", age_group = "5-21")`

## Value

tidy tibble
