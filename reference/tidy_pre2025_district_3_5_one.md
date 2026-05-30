# Tidy one pre-2025 3-5 district subgroup workbook

The 3-5 district files are count-only (no environment dimension). For
each (district x subgroup) pair we emit one row with
`environment = "districtwide"`, matching the 2025 3-5 District Counts
behavior so the schema is uniform across years.

## Usage

``` r
tidy_pre2025_district_3_5_one(df, subgroup_dim)
```

## Arguments

- df:

  raw tibble for the subgroup_dim

- subgroup_dim:

  "race" / "gender" / "disability" / "lep"

## Value

tidy tibble
