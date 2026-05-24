# Fetch Statewide Educator Equity Metrics

Downloads the `StatewideEducatorEquity` sheet from the redesigned
2024-25 School Performance Reports (District/State database only). This
is a statewide summary table comparing high-need student groups
(economically disadvantaged students in Title I schools, minority
students in Title I schools) against their counterparts on
educator-equity measures such as the share of students taught by
out-of-field or inexperienced teachers.

## Usage

``` r
fetch_spr_educator_equity(end_year)
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

## Value

Data frame with end_year, school_year, category, classes_included, and
the metric columns (all_students plus the compared student groups).

## Details

This is a statewide summary table with no county/district/school
identifiers, so it returns no CDS columns or aggregation flags. Each row
is a `category` (the equity measure) for a set of `classes_included`
(e.g. Core Classes vs. All Classes); the five metric columns hold the
proportion (0-1 scale, as published) for All Students and for each
compared student group.

**Supported years:** only `end_year >= 2025`. Always reads the
District/State database.

## Examples

``` r
if (FALSE) { # \dontrun{
equity <- fetch_spr_educator_equity(2025)

# Out-of-field teaching gap, core classes
library(dplyr)
fetch_spr_educator_equity(2025) %>%
  filter(grepl("out-of-field", category, ignore.case = TRUE),
         classes_included == "Core Classes") %>%
  select(category, all_students,
         economically_disadvantaged_students_in_title_i_schools)
} # }
```
