# Fetch Chronic Absenteeism Data (Cross-State Standard)

Unified entry point for NJ chronic absenteeism data, matching the
`fetch_absence()` naming convention used across all state packages.
Wraps
[`fetch_chronic_absenteeism()`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md)
from the SPR database with optional tidy normalization.

## Usage

``` r
fetch_absence(
  end_year,
  level = "school",
  type = "chronic",
  tidy = TRUE,
  use_cache = TRUE
)
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year —
  e.g., the 2023-24 school year is `end_year = 2024`.

- level:

  One of `"school"` or `"district"`. Default `"school"` returns
  school-level data; `"district"` returns district and state-level data.

- type:

  One of `"chronic"` (default), `"by_grade"`, `"days_absent"`, or
  `"essa"`. Selects which underlying absenteeism function to call.

- tidy:

  Logical; if `TRUE` (default), normalizes subgroup names to cross-state
  standards (e.g., `"econ_disadv"`, `"lep"`, `"special_ed"`).

- use_cache:

  Logical; if `TRUE`, uses session cache for faster repeat calls.

## Value

A data frame with chronic absenteeism data. When `tidy = TRUE`, subgroup
names are standardized:

- `total` — total population

- `white`, `black`, `hispanic`, `asian` — race/ethnicity

- `native_american`, `pacific_islander`, `multiracial`

- `econ_disadv` — economically disadvantaged

- `lep` — limited English proficiency

- `special_ed` — students with disabilities

- `male`, `female`

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school-level chronic absenteeism with standard subgroup names
ca <- fetch_absence(2024)

# District-level data
ca_dist <- fetch_absence(2024, level = "district")

# Grade-level breakdown
ca_grade <- fetch_absence(2024, type = "by_grade")

# Days absent distribution
days <- fetch_absence(2024, type = "days_absent")

# ESSA chronic absenteeism (school-level only)
essa <- fetch_absence(2024, type = "essa")

# Without tidy normalization (original NJ subgroup names)
ca_raw <- fetch_absence(2024, tidy = FALSE)

# Cross-state filtering patterns
library(dplyr)
ca %>%
  filter(subgroup == "econ_disadv", is_district) %>%
  arrange(desc(chronically_absent_rate))
} # }
```
