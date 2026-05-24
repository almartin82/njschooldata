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

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, teachers_admins,
retention_pct_district, retention_pct_state, and the aggregation flags.

## Details

`teachers_admins` labels the group. `retention_pct_district` and
`retention_pct_state` are returned numeric percentages (suppressed cells
set to `NA`).

**Supported years:** only `end_year >= 2025`.

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
} # }
```
