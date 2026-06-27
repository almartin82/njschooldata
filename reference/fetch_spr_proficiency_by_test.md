# Fetch NJSLA Proficiency by Test Variant

Downloads the `ELAPerformanceByTest` or `MathPerformancebyTest` sheet
from the redesigned 2024-25 School Performance Reports. Unlike
[`fetch_parcc`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
(which reports overall ELA/Math proficiency), these sheets break results
out by the specific test a student sat: for ELA the grade-level NJSLA
tests (Grade 3 through Grade 9), and for Math the grade-level NJSLA
tests (Grade 3 through Grade 8) plus the high-school end-of-course
assessments `Algebra I`, `Geometry`, and `Algebra II`. The test label is
carried in `grade_test`.

## Usage

``` r
fetch_spr_proficiency_by_test(end_year, subject = "ela", level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- subject:

  One of `"ela"` (default) or `"math"`.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, subject, grade_test,
subgroup, valid_scores, mean_scaled_score, proficiency_rate,
level_1..level_5, and the aggregation flags.

## Details

For each entity, student group, and test, the sheet reports
`valid_scores` (the number of valid test takers), `mean_scaled_score`,
`proficiency_rate` (percent at NJSLA level 4 or 5, the proficiency
threshold), and the percentage at each of the five performance levels
(`level_1`..`level_5`). In the source these values are each repeated as
a `_school` / `_district` / `_state` triple; this function returns the
entity-appropriate value (see the entity-pick note in the package
source). The statewide value is available from the `is_state` row of
district-level output.

This sheet ships as a multi-year trend table inside the 2025 workbook
(`school_year` 2021-22..2024-25); per the package convention this
function filters to the requested academic year (SY2024-25 for
`end_year` 2025). The pre-COVID and COVID years (no spring 2020/2021
statewide NJSLA testing) are not present.

**Supported years:** only `end_year >= 2025`. The `ELAPerformanceByTest`
/ `MathPerformancebyTest` sheets are new in the SY2024-25 redesign;
earlier databases carry differently structured assessment sheets (e.g.
`MathPerformanceByGradeTest`) and are not mapped here.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level ELA proficiency by test
ela <- fetch_spr_proficiency_by_test(2025, subject = "ela")

# Statewide Algebra I vs grade-level Math proficiency
library(dplyr)
fetch_spr_proficiency_by_test(2025, subject = "math", level = "district") %>%
  filter(is_state, subgroup == "total population") %>%
  select(grade_test, valid_scores, proficiency_rate)

# Schools with the largest Algebra I proficiency gap for economically
# disadvantaged students
fetch_spr_proficiency_by_test(2025, subject = "math") %>%
  filter(is_school, grade_test == "Algebra I",
         subgroup %in% c("total population", "economically disadvantaged")) %>%
  select(district_name, school_name, subgroup, proficiency_rate)
} # }
```
