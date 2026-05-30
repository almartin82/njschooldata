# Tidy one pre-2025 5-21 district subgroup workbook

Handles one of the four single-subgroup workbooks (race, gender,
disability, lep) published for end_years 2020-2024. Counts only (no
percent column was published in these files); percent is therefore NA.

## Usage

``` r
tidy_pre2025_district_5_21_one(df, subgroup_dim)
```

## Arguments

- df:

  raw tibble from `get_raw_sped_placement(...)` for the subgroup
  dimension

- subgroup_dim:

  "race" / "gender" / "disability" / "lep"

## Value

tidy tibble in the canonical schema
