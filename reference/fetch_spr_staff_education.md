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

  A school year (2018-2025). Year is the end of the academic year - e.g.
  the 2020-21 school year is `end_year` 2021.

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

**Supported years:** `end_year >= 2018`. Before the 2024-25 redesign
this sheet was named `TeachersAdminsLevelOfEducation`; the
Bachelor's/Master's/Doctoral layout is identical from SY2017-18 on (this
function selects the right sheet by year). The legacy sheet labels the
administrator row `"Admin"`; it is normalized to `"Administrators"` for
cross-year consistency. The SY2016-17 sheet uses a different long-format
layout and is not supported.

## Examples

``` r
if (FALSE) { # \dontrun{
edu <- fetch_spr_staff_education(2025)

# The same degree distribution back to SY2017-18
edu_2018 <- fetch_spr_staff_education(2018)

# Share of teachers with a Master's degree, by school
library(dplyr)
fetch_spr_staff_education(2025) %>%
  filter(is_school, teachers_admins == "Teachers") %>%
  select(district_name, school_name, masters, doctoral)
} # }
```
