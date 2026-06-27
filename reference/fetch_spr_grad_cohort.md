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

  A school year (2020-2025). Year is the end of the academic year - e.g.
  the 2020-21 school year is `end_year` 2021.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year (2025 only),
cohort_type, subgroup, graduated, continuing, non_continuing,
persisting, and the aggregation flags.

## Details

Each outcome rate is repeated as a `_school` / `_district` / `_state`
triple in the source; this function returns the entity-appropriate value
(the statewide value is available from the `is_state` row of
district-level output). Rates are percentages on a 0-100 scale;
suppressed cells (fewer than 10 students) become `NA`.

In SY2024-25 (`end_year` 2025) this reads the single combined
`GraduationCohortProfile` sheet. For `end_year` 2020-2024 it stacks the
separate `4YrGraduationCohortProfile` / `5YrGraduationCohortProfile` /
`6YrGraduationCohortProfile` sheets (the pre-redesign predecessors,
identical columns) into the same `cohort_type` long shape. The 4- and
6-year cohort rates are also available through
[`fetch_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)
and
[`fetch_6yr_grad_rate`](https://almartin82.github.io/njschooldata/reference/fetch_6yr_grad_rate.md);
this function additionally exposes the 5-year cohort and presents all
available cohort lengths in one tidy frame.

**Supported years:** `end_year >= 2020`. The 6-year cohort first appears
in SY2020-21 (`end_year` 2021), so `end_year` 2020 returns only the 4-
and 5-year cohorts. Earlier databases (2017-2019) do not carry
cohort-profile sheets and error. The pre-2025 sheets report no
per-cohort `school_year` column, so that column is present only for
2025. `persisting` is published only for the 6-year cohort (and only
from `end_year` 2024 in the pre-redesign sheets); it is `NA` otherwise.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level cohort profile (all available cohort lengths)
gc <- fetch_spr_grad_cohort(2025)

# The same shape from a pre-redesign year
gc_2022 <- fetch_spr_grad_cohort(2022)

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
