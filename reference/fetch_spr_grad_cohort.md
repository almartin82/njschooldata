# Fetch Graduation Cohort Profile (4/5/6-Year)

Downloads the combined `GraduationCohortProfile` sheet from the
redesigned 2024-25 School Performance Reports. For each entity, cohort
length (`cohort_type` in `"4-Year"`, `"5-Year"`, `"6-Year"`), and
student group it reports the cohort's outcome distribution: the
percentage who `graduated`, are `continuing` (still enrolled), are
`non_continuing` (left without graduating), and the high-school
`persisting` rate (graduated plus continuing; published for the 6-Year
cohort, `NA` for shorter cohorts).

## Usage

``` r
fetch_spr_grad_cohort(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, cohort_type, subgroup,
graduated, continuing, non_continuing, persisting, and the aggregation
flags.

## Details

Each outcome rate is repeated as a `_school` / `_district` / `_state`
triple in the source; this function returns the entity-appropriate value
(the statewide value is available from the `is_state` row of
district-level output). Rates are percentages on a 0-100 scale;
suppressed cells (fewer than 10 students) become `NA`.

This sheet is the SY2024-25 successor to the separate
`4YrGraduationCohortProfile` / `5YrGraduationCohortProfile` /
`6YrGraduationCohortProfile` sheets used in 2017-2024. The 4- and 6-year
cohort rates are also available (in their pre-redesign form) through
[`fetch_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
and
[`fetch_6yr_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md);
this function additionally exposes the 5-year cohort and presents all
three cohort lengths in one tidy frame.

**Supported years:** only `end_year >= 2025`. Earlier databases do not
carry the combined `GraduationCohortProfile` sheet (their per-length
cohort profiles are reached via
[`fetch_6yr_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md)).

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level cohort profile (all three cohort lengths)
gc <- fetch_spr_grad_cohort(2025)

# Statewide 4-year cohort outcomes
library(dplyr)
fetch_spr_grad_cohort(2025, level = "district") %>%
  filter(is_state, cohort_type == "4-Year", subgroup == "total population") %>%
  select(graduated, continuing, non_continuing)

# How much does the graduation rate rise from the 4- to the 6-year cohort?
fetch_spr_grad_cohort(2025, level = "district") %>%
  filter(is_state, subgroup == "total population") %>%
  select(cohort_type, graduated)
} # }
```
