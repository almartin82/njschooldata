# Fetch Teacher Experience by Subject Area

Downloads the `TeacherExperienceSubjArea` sheet from the redesigned
2024-25 School Performance Reports: by subject area, the percentage of
teachers with 4+ years of experience and the highest-degree
distribution.

## Usage

``` r
fetch_spr_teacher_exp_subject(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, subject_area, teacher_count,
fourormoreyearsexp, bachelors, masters, doctoral, and the aggregation
flags.

## Details

`teacher_count` is returned numeric. `fourormoreyearsexp`, `bachelors`,
`masters`, and `doctoral` are returned numeric percentages (cells
reading “There is no data available for this school year.” set to `NA`).

**Supported years:** only `end_year >= 2025`.

## Examples

``` r
if (FALSE) { # \dontrun{
exp <- fetch_spr_teacher_exp_subject(2025)

# Experience of math teachers by school
library(dplyr)
fetch_spr_teacher_exp_subject(2025) %>%
  filter(is_school, subject_area == "Mathematics") %>%
  select(district_name, school_name, teacher_count, fourormoreyearsexp)
} # }
```
