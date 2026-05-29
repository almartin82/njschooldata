# Tidy the 3-5 District Counts sheet (preschool, totals only)

The preschool district sheet does NOT carry an environment dimension –
it only has a districtwide total per (district, student group). The tidy
output has the same column shape as the school-age district output, with
`environment = "districtwide"` and `count`/`percent` taken from the
workbook's Districtwide Total / Districtwide Percent columns. This keeps
a uniform tidy schema across age groups.

## Usage

``` r
tidy_sped_placement_district_3_5(df)
```

## Arguments

- df:

  raw tibble from
  `get_raw_sped_placement(level = "district", age_group = "3-5")`

## Value

tidy tibble
