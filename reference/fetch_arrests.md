# Fetch Student Arrests (by Student Group / Grade)

Downloads the SPR sheet that reports arrest counts by student subgroup
(race, gender, ED, SwD) and by grade level. Each row reports, for one
entity and one label (where the label is either a subgroup or a grade),
counts and percents for the seven arrest-related incident categories.
The label dimension is normalized into a separate `subgroup` +
`grade_level` pair so downstream code can filter the two dimensions
independently.

## Usage

``` r
fetch_arrests(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Supported: `2024` (SY2023-24) and `2025` (SY2024-25).
  Earlier years error.

- level:

  One of `"school"` or `"district"`. `"school"` returns school-level
  data; `"district"` returns district and state-level data.

## Value

Data frame with entity identifiers, `student_group_grade`, `subgroup`
and `grade_level`, `arrested_count`, six per-category counts
(`arrested_violent_count`, `arrested_vandalism_count`,
`arrested_substance_count`, `arrested_weapons_count`,
`arrested_hibcount`, `arrested_other_count`) and their matching percent
columns, the 2025-only `school_year` column when present, and the
standard aggregation flags.

## Details

Sheet coverage and harmonization:

- The arrests sheet first appears in SY2023-24 (end_year 2024) and is
  **absent** from every earlier SPR workbook. The function errors for
  `end_year < 2024`.

- Year-aliased sheet names:

  - 2024: `StuArrestbyStudentGroupGradelev`

  - 2025: `ArrestsStudentGroupGrade`

- **Upstream NJ DOE column-label bug, SY2024-25:** the 2025
  `ArrestsStudentGroupGrade` sheet ships with column headers
  `Police_Count`, `Violent_Count`, etc. (a copy-paste from the companion
  Police Notifications detail sheet). The values are arrest counts, not
  police-notification counts. This fetcher renames the seven `police_*`
  / `violent_*` / etc. columns to the canonical `arrested_*` prefix used
  by the 2024 sheet, so the public API is consistent across years.

- The raw label column (`student_group_grade_level` in 2024;
  `student_group_grade` in 2025) is preserved and additionally split
  into normalized `subgroup` + `grade_level` columns (`"PK"`, `"K"`,
  `"01"-"12"`, or `"TOTAL"` for subgroup marginals).

- The 2025 sheet adds a `school_year` column (single value, e.g.
  `"2024-25"`); preserved in the output. The 2024 sheet has no
  `school_year` column.

- All seven count columns (`arrested_count` + six incident categories)
  and their percent counterparts are returned numeric; suppressed cells
  (NJ DOE uses `*`, `N`, `-`, `<5`) become `NA`.

Pair with
[`calc_discipline_rates_by_subgroup`](https://almartin82.github.io/njschooldata/reference/calc_discipline_rates_by_subgroup.md)
(with `by_grade = TRUE` when interested in the grade dimension) to
compute disproportionality rates and risk ratios.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level arrest detail (latest year)
arr <- fetch_arrests(2025)

# District/state-level arrests by subgroup
library(dplyr)
fetch_arrests(2024, level = "district") %>%
  filter(is_district, grade_level == "TOTAL") %>%
  select(district_name, subgroup, arrested_count, arrested_violent_count)

# Statewide arrest rates by grade
fetch_arrests(2025, level = "district") %>%
  filter(is_state, grade_level != "TOTAL") %>%
  select(grade_level, arrested_count, arrested_violent_count)
} # }
```
