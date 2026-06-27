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

  A school year (2017-2019 or 2022-2025). Year is the end of the
  academic year - e.g. the 2022-23 school year is `end_year` 2023.

- subject:

  One of `"ela"` (default) or `"math"`.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year (2025 only), subject,
grade_test, subgroup, valid_scores, mean_scaled_score, proficiency_rate,
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

In SY2024-25 (`end_year` 2025) this sheet ships as a multi-year trend
table inside the workbook (`school_year` 2021-22..2024-25); the function
filters to the requested academic year. For `end_year` 2017-2019 and
2022-2024 it reads the pre-redesign predecessors (ELA:
`ELALiteracyPerformanceByGrade` 2017-2019, `ELAPerformanceByGrade`
2022-2024; Math: `MathPerformanceByGradeTest` throughout) and harmonizes
their drifting column names onto the same schema. The end-of-course Math
tests appear in every era (raw `ALG01`/`ALG02`/`GEO01` in the
pre-redesign sheets, normalized to `Algebra I`/`Algebra II`/
`Geometry`); grade labels (`Grade 03`) are normalized to the 2025 form
(`Grade 3`).

**Supported years:** 2017-2019 and 2022-2025. The 2020 and 2021
databases carry no by-grade/test ELA or Math sheet (no spring 2020
statewide NJSLA, and SY2020-21 did not publish this breakdown), so those
years error.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level ELA proficiency by test
ela <- fetch_spr_proficiency_by_test(2025, subject = "ela")

# The same shape from a pre-redesign year
math_2023 <- fetch_spr_proficiency_by_test(2023, subject = "math")

# Statewide Algebra I vs grade-level Math proficiency
library(dplyr)
fetch_spr_proficiency_by_test(2025, subject = "math", level = "district") %>%
  filter(is_state, subgroup == "total population") %>%
  select(grade_test, valid_scores, proficiency_rate)
} # }
```
