# Fetch NJSLA Science Proficiency by Grade

Downloads the `NJSLASciencebyGradeTrends` sheet from the redesigned
2024-25 School Performance Reports. The NJSLA Science assessment is
given at grades 5, 8, and 11; for each entity, student group, and grade
the sheet reports the percentage of valid test takers at each of the
four NJSLA Science performance levels.

## Usage

``` r
fetch_spr_science_grade(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, subgroup, grade,
grade_level, level_1_percentage..level_4_percentage, and the aggregation
flags.

## Details

The four level percentages (`level_1_percentage`..`level_4_percentage`)
are each repeated as a `_school` / `_district` / `_state` triple in the
source; this function returns the entity-appropriate value (the
statewide value is available from the `is_state` row of district-level
output). NJSLA Science proficiency is conventionally levels 3 and 4
combined; the level percentages are returned as published and not summed
here. `grade_level` normalizes the raw `grade` label (`"Grade 5"`) to
the package's two-digit convention (`"05"`, `"08"`, `"11"`).

This sheet ships as a multi-year trend table inside the 2025 workbook
(`school_year` 2021-22..2024-25; the earlier COVID years carry no spring
science testing); per the package convention this function filters to
the requested academic year (SY2024-25 for `end_year` 2025).

**Supported years:** only `end_year >= 2025`. The
`NJSLASciencebyGradeTrends` sheet is new in the SY2024-25 redesign;
earlier databases carry differently structured science sheets
(`NJSLAScienceTable`, `NJASKScience`) and are not mapped here.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level NJSLA science by grade
sci <- fetch_spr_science_grade(2025)

# Statewide grade-5 science level distribution
library(dplyr)
fetch_spr_science_grade(2025, level = "district") %>%
  filter(is_state, subgroup == "total population", grade_level == "05") %>%
  select(grade, level_1_percentage, level_2_percentage,
         level_3_percentage, level_4_percentage)

# Schools with the highest grade-8 level-4 share
fetch_spr_science_grade(2025) %>%
  filter(is_school, subgroup == "total population", grade_level == "08") %>%
  slice_max(level_4_percentage, n = 10) %>%
  select(district_name, school_name, level_4_percentage)
} # }
```
