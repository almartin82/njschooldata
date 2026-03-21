# Fetch Chronic Absenteeism Data for Multiple Years

Convenience wrapper that calls
[`fetch_absence()`](https://almartin82.github.io/njschooldata/reference/fetch_absence.md)
for each year and binds the results. Skips years that fail (e.g., COVID
gap 2020-2021) with a warning.

## Usage

``` r
fetch_absence_multi(
  end_years,
  level = "school",
  type = "chronic",
  tidy = TRUE,
  use_cache = TRUE
)
```

## Arguments

- end_years:

  Integer vector of school years (e.g., `2017:2024`).

- level:

  One of `"school"` or `"district"`.

- type:

  One of `"chronic"`, `"by_grade"`, `"days_absent"`, or `"essa"`.

- tidy:

  Logical; if `TRUE` (default), normalizes subgroup names.

- use_cache:

  Logical; if `TRUE` (default), caches each year.

## Value

A data frame with all years bound together.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all available years of chronic absenteeism
ca_all <- fetch_absence_multi(2017:2024)

# COVID gap: 2020-2021 were not reported, will be skipped with a warning
ca_all <- fetch_absence_multi(2017:2024)

# Multi-year trend by district
library(dplyr)
ca_all %>%
  filter(subgroup == "total", is_state) %>%
  select(end_year, chronically_absent_rate)
} # }
```
