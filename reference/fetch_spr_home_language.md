# Fetch Enrollment by Home Language

Downloads the `EnrollmentByHomeLanguage` sheet from the redesigned
2024-25 School Performance Reports. For each entity it reports the
percentage of students by reported home language (e.g. English, Spanish,
and an "Others" catch-all). This breakdown is not available through
[`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md).

## Usage

``` r
fetch_spr_home_language(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2018-2025). Year is the end of the academic year - e.g.
  the 2020-21 school year is `end_year` 2021.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, home_language,
percent_of_students, and the aggregation flags.

## Details

`percent_of_students` is returned numeric on a 0-100 scale (suppressed
cells become `NA`).

**Supported years:** `end_year >= 2018`. The `EnrollmentByHomeLanguage`
sheet is present back to SY2017-18 with an identical layout (the 2024-25
redesign only added a `SchoolYear` column, handled transparently). The
SY2016-17 sheet omits the county/district/school name columns and is not
supported.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level home-language shares
hl <- fetch_spr_home_language(2025)

# The same breakdown back to SY2017-18
hl_2018 <- fetch_spr_home_language(2018)

# Statewide home-language distribution
library(dplyr)
fetch_spr_home_language(2025, level = "district") %>%
  filter(is_state) %>%
  arrange(desc(percent_of_students)) %>%
  select(home_language, percent_of_students)

# Schools with the highest Spanish home-language share
fetch_spr_home_language(2025) %>%
  filter(is_school, home_language == "Spanish") %>%
  slice_max(percent_of_students, n = 10) %>%
  select(district_name, school_name, percent_of_students)
} # }
```
