# Fetch NJ school finance in the canonical cross-state schema

The uniform front door for NJ school finance. Consolidates the two NJ
DOE finance sources this package already pulls - per-pupil spending from
the Taxpayers' Guide to Educational Spending
([`fetch_tges`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md))
and total K-12 state aid from the Governor's Budget Message district
details
([`fetch_state_aid`](https://almartin82.github.io/njschooldata/reference/fetch_state_aid.md)) -
onto one tidy schema with a standard `metric` vocabulary, so cross-state
code works unchanged.

## Usage

``` r
fetch_finance(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  school year (end of the academic year). See
  [`get_available_finance_years`](https://almartin82.github.io/njschooldata/reference/get_available_finance_years.md)
  for valid values.

- tidy:

  logical, default `TRUE`. The tidy long schema is the only supported
  (and only) shape; `tidy = FALSE` currently returns the same long frame
  and is reserved for a future wide form.

- use_cache:

  logical, default `TRUE`. Reserved for parity with other fetchers; the
  underlying TGES/state-aid downloads use the package session cache.

## Value

A tibble in the canonical finance schema: `end_year`, `state_id`,
`entity_name`, `county`, `is_state`, `is_district`, `is_school`,
`is_charter`, `nces_dist`, `nces_sch`, `metric`, `value`,
`is_per_pupil`, `enrollment_denominator`.

## Details

**FY \<-\> SY mapping.** `end_year` is the fiscal / school year END:
`end_year = 2024` is FY2024, school year 2023-24. NJ publishes a year's
spending ACTUALS in the guide released the following year, so the
spending side fetches the `end_year + 1` guide and keeps the actuals;
state aid is appropriated for the named year and is read directly.

**Metrics emitted.**

- `per_pupil_total` - total per-pupil expenditures (ESSA-style), with
  `enrollment_denominator` = average daily enrollment plus sent pupils.
  Carries a statewide-average row (`is_state`).

- `per_pupil_instruction` - classroom instruction per pupil.

- `per_pupil_support_services`, `per_pupil_administration`,
  `per_pupil_operations_maintenance`, `per_pupil_food_service` -
  NJ-specific per-pupil category metrics (NJ reports these per-pupil
  rather than as absolute totals).

- `revenue_state` - total K-12 state aid (absolute dollars). Carries a
  statewide-total row.

Years 2025+ carry `revenue_state` only (that year's spending actuals are
not yet published); years before 2019 carry per-pupil spending only.
Values are nominal dollars exactly as published - no rescaling, no
fabrication. The federal `nces_dist` identifier is attached from the
bundled CCD crosswalk; unmatched districts keep `NA`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# One year, all metrics
fin <- fetch_finance(2024)
fin %>% count(metric)

# Per-pupil total spending, highest-spending districts
fetch_finance(2024) %>%
  filter(is_district, metric == "per_pupil_total") %>%
  arrange(desc(value)) %>%
  select(entity_name, value, enrollment_denominator)

# Statewide per-pupil total
fetch_finance(2024) %>%
  filter(is_state, metric == "per_pupil_total") %>%
  select(end_year, value)

# Total K-12 state aid for one district
fetch_finance(2024) %>%
  filter(metric == "revenue_state", state_id == "3570") %>%
  select(entity_name, value)
} # }
```
