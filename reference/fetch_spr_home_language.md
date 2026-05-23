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

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, home_language,
percent_of_students, and the aggregation flags.

## Details

`percent_of_students` is returned numeric on a 0-100 scale (suppressed
cells become `NA`).

**Supported years:** only `end_year >= 2025` (the redesigned SY2024-25
SPR). Earlier databases do not include this sheet.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level home-language shares
hl <- fetch_spr_home_language(2025)

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
