# Fetch Teacher Experience Data

Downloads teacher experience data from SPR database.

## Usage

``` r
fetch_teacher_experience(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2019-2025)

- level:

  One of "school" or "district"

## Value

Data frame with teacher experience breakdown

Supported end_year values are 2019-2025; earlier workbooks lack
TeachersExperience. Out-of-field teacher counts are unavailable in 2019.
Percentage and provisional-credential fields begin in 2023 and are NA in
earlier years. The 2023 district-suffixed out-of-field teacher number
and percentage labels are harmonized to the unsuffixed entity carriers
for those same measures. Source school/district experience carriers and
legacy four-year-experience fields remain separate where the labels do
not establish an identical quantity and unit. Unpublished fields are NA.

## Examples

``` r
if (FALSE) { # \dontrun{
teachers <- fetch_teacher_experience(2024)
} # }
```
