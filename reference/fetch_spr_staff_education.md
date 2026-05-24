# Fetch Teacher and Administrator Education

Downloads the `TeachersAdminsEducation` sheet from the redesigned
2024-25 School Performance Reports: the highest-degree distribution
(Bachelor's, Master's, Doctoral) for teachers and for administrators.

## Usage

``` r
fetch_spr_staff_education(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, teachers_admins, bachelors, masters,
doctoral, and the aggregation flags.

## Details

`teachers_admins` labels the group (`"Teachers"` or `"Administrators"`).
The degree columns are returned numeric percentages
(suppressed/non-numeric cells, including the administrator note that
administrators must hold a Master's or higher, set to `NA`).

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
edu <- fetch_spr_staff_education(2025)

# Share of teachers with a Master's degree, by school
library(dplyr)
fetch_spr_staff_education(2025) %>%
  filter(is_school, teachers_admins == "Teachers") %>%
  select(district_name, school_name, masters, doctoral)
} # }
```
