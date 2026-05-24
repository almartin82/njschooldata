# Fetch Teacher Demographics by Subject Area

Downloads the `TeachersAdminsDemoSubjectArea` sheet from the redesigned
2024-25 School Performance Reports: teacher racial/ethnic and gender
composition by subject area.

## Usage

``` r
fetch_spr_staff_demo_subject(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, subject_area, teacher_count, the
racial/ethnic and gender composition columns (character), and the
aggregation flags.

## Details

`teacher_count` is returned numeric. The racial/ethnic and gender
percentage columns are kept as **character** on purpose: NJ DOE reports
small-cell percentages as privacy-protected ranges (e.g. `"70-80%"`,
`"<=10%"`), and coercing a range to a single number would fabricate
precision. Exact percentages (e.g. `"91.9%"`) are likewise preserved as
published. Cells reading “There is no data available for this school
year.” are set to `NA`. The `TwoorMoreRaces` column is renamed to
`two_or_more_races`.

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
demo <- fetch_spr_staff_demo_subject(2025)

# All-teacher racial composition for a school
library(dplyr)
fetch_spr_staff_demo_subject(2025) %>%
  filter(is_school, subject_area == "All Teachers") %>%
  select(district_name, school_name, white, black_african_american,
         hispanic_latino, asian)
} # }
```
