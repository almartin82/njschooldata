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

  A school year (2019 or 2021-2025). Year is the end of the academic
  year - e.g. the 2021-22 school year is `end_year` 2022.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year (2025 and 2021 only),
subgroup, grade, grade_level, level_1_percentage..level_4_percentage,
and the aggregation flags.

## Details

The four level percentages (`level_1_percentage`..`level_4_percentage`)
are each repeated as a `_school` / `_district` / `_state` triple in the
source; this function returns the entity-appropriate value (the
statewide value is available from the `is_state` row of district-level
output). NJSLA Science proficiency is conventionally levels 3 and 4
combined; the level percentages are returned as published and not summed
here. `grade_level` normalizes the raw `grade` label (`"Grade 5"`) to
the package's two-digit convention (`"05"`, `"08"`, `"11"`).

In SY2024-25 (`end_year` 2025) this reads the multi-year trend table
`NJSLASciencebyGradeTrends` and filters to the requested academic year.
For `end_year` 2019 and 2021-2024 it reads the pre-redesign NJSLA
science predecessors and harmonizes them: `NJSLAScienceTable` (2019) and
`NJSLAScience` (2021) carry the four level percentages directly
(`level_1`..`level_4`); `ScienceAssessmentByGrade` (2022-2024) stores
the entity's value in `percent_level_*` and the statewide value in
`performance_level_*_perc`. `grade_level` normalizes the raw grade
(`"Grade 5"` or `"5"`) to the two-digit form (`"05"`, `"08"`, `"11"`).

**Supported years:** 2019 and 2021-2025. NJSLA Science began in spring
2019; the 2020 database carries no science results (no spring 2020
testing), and the 2017-2018 databases report the earlier `NJASKScience`
assessment on a different scale (not comparable, not mapped). Those
years error.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level NJSLA science by grade
sci <- fetch_spr_science_grade(2025)

# The same shape from a pre-redesign year
sci_2022 <- fetch_spr_science_grade(2022)

# Statewide grade-5 science level distribution
library(dplyr)
fetch_spr_science_grade(2025, level = "district") %>%
  filter(is_state, subgroup == "total population", grade_level == "05") %>%
  select(grade, level_1_percentage, level_2_percentage,
         level_3_percentage, level_4_percentage)
} # }
```
