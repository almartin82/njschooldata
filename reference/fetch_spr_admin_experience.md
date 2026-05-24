# Fetch Administrator Experience

Downloads the `AdministratorsExperience` sheet from the redesigned
2024-25 School Performance Reports: administrator counts and experience
summaries for the entity alongside the statewide comparison.

## Usage

``` r
fetch_spr_admin_experience(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, the administrator experience
measures, and the aggregation flags.

## Details

Reported measures (each with a `*_school` entity value and a `*_state`
statewide comparison): administrator count, average years of experience
in public schools, average years of experience in the district, and the
number and percentage of administrators with 4+ years of experience. All
value columns are returned numeric (thousands commas and percent signs
stripped; suppressed cells set to `NA`).

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
admin <- fetch_spr_admin_experience(2025)

# Schools where every administrator has 4+ years of experience
library(dplyr)
fetch_spr_admin_experience(2025) %>%
  filter(is_school, percentage_admins_with_4_or_more_years_exp_school == 100) %>%
  select(district_name, school_name, admin_count_school)

# District-level average administrator experience
fetch_spr_admin_experience(2025, level = "district") %>%
  filter(is_district) %>%
  select(district_name, average_years_exp_in_public_schools_school)
} # }
```
