# Fetch Teacher and Administrator One-Year Retention

Downloads the `TeachersAdminsOneYearRetention` sheet from the redesigned
2024-25 School Performance Reports: the one-year retention rate for
teachers and for administrators, for the district and the state.

## Usage

``` r
fetch_spr_staff_retention(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. `level = "district"` accepts 2018-2025;
  `level = "school"` accepts 2025 only. Year is the end of the academic
  year - e.g. the 2020-21 school year is `end_year` 2021.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, teachers_admins,
retention_pct_district, retention_pct_state, and the aggregation flags.

## Details

`teachers_admins` labels the group. `retention_pct_district` and
`retention_pct_state` are returned numeric percentages (suppressed cells
set to `NA`).

**Supported years:** `level = "district"` is supported for
`end_year >= 2018`; `level = "school"` only for `end_year >= 2025`. The
retention measure is reported at district/state granularity (no
`SchoolCode`) in every SPR database through SY2023-24; the 2024-25
redesign was the first to add per-school retention rows. For earlier
years, use `level = "district"`. (The SY2016-17 sheet additionally omits
entity-name columns and is not supported.)

## Examples

``` r
if (FALSE) { # \dontrun{
ret <- fetch_spr_staff_retention(2025)

# Districts with the lowest teacher retention
library(dplyr)
fetch_spr_staff_retention(2025, level = "district") %>%
  filter(is_district, teachers_admins == "Teachers") %>%
  slice_min(retention_pct_district, n = 10) %>%
  select(district_name, retention_pct_district, retention_pct_state)

# District/state retention back to SY2017-18
ret_2018 <- fetch_spr_staff_retention(2018, level = "district")
} # }
```
