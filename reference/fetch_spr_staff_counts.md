# Fetch Staff Counts

Downloads the `StaffCounts` sheet from the redesigned 2024-25 School
Performance Reports: counts of staff by role (`staff_category`, e.g.
Administrators, Teachers, Child Study Team Members) for the school,
district, and state.

## Usage

``` r
fetch_spr_staff_counts(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, staff_category, the three staff
count columns, and the aggregation flags.

## Details

The three count columns (`school_total_staff`,
`district_total_staff_members`, `state_total_staff_members`) are
returned numeric (thousands commas stripped; cells reading “There is no
data available for this school year.” set to `NA`).

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
staff <- fetch_spr_staff_counts(2025)

# Teacher counts by school
library(dplyr)
fetch_spr_staff_counts(2025) %>%
  filter(is_school, staff_category == "Teachers") %>%
  select(district_name, school_name, school_total_staff)

# Statewide staff by role
fetch_spr_staff_counts(2025, level = "district") %>%
  filter(is_state) %>%
  select(staff_category, state_total_staff_members)
} # }
```
