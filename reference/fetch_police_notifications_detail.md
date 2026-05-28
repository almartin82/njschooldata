# Fetch Police Notifications Detail (by Student Group / Grade)

Downloads the SPR detail sheet that breaks police-notification incident
counts out by student subgroup (race, gender, ED, SwD) and by grade
level. Each row reports, for one entity and one label (where the label
is either a subgroup or a grade), counts and percents for the seven
police-related incident categories. The label dimension is normalized
into a separate `subgroup` + `grade_level` pair so downstream code can
filter on the two dimensions independently.

## Usage

``` r
fetch_police_notifications_detail(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Supported: `2024` (SY2023-24) and `2025` (SY2024-25).
  Earlier years error.

- level:

  One of `"school"` or `"district"`. `"school"` returns school-level
  data; `"district"` returns district and state-level data.

## Value

Data frame with entity identifiers, `student_group_grade` (raw label),
`subgroup` and `grade_level` (normalized), `police_count`, six
per-category counts (`violent_count`, `vandalism_count`,
`substance_count`, `weapons_count`, `hibcount`, `other_count`) and their
matching percent columns, the 2025-only `school_year` column when
present, and the standard aggregation flags (`is_state`, `is_county`,
`is_district`, `is_school`, `is_charter`, `is_charter_sector`,
`is_allpublic`).

## Details

Sheet coverage and harmonization:

- The detail sheet first appears in SY2023-24 (end_year 2024) and is
  **absent** from every earlier SPR workbook. The function errors for
  `end_year < 2024`.

- Year-aliased sheet names:

  - 2024: `PoliceNotificationByStuGroup`

  - 2025: `PoliceNotificationsGroupGrade`

- The raw label column (`student_group_grade_level` in 2024;
  `student_group_grade` in 2025) is preserved as `student_group_grade`
  and additionally split into normalized `subgroup` + `grade_level`
  columns. Subgroup rows get `grade_level = "TOTAL"`; grade rows get
  `subgroup = "total population"` and a project-standard grade label
  (`"PK"`, `"K"`, `"01"-"12"`).

- Subgroup labels are normalized via the same
  [`clean_spr_subgroups`](https://almartin82.github.io/njschooldata/reference/clean_spr_subgroups.md)
  machinery used by every other SPR fetcher.

- The 2025 sheet adds a `school_year` column (single value, e.g.
  `"2024-25"`); preserved in the output. The 2024 sheet has no
  `school_year` column.

- All seven count columns (`police_count` + six incident categories) and
  their percent counterparts are returned numeric; suppressed cells (NJ
  DOE uses `*`, `N`, `-`, `<5`) become `NA`.

Pair with
[`calc_discipline_rates_by_subgroup`](https://almartin82.github.io/njschooldata/reference/calc_discipline_rates_by_subgroup.md)
(with `by_grade = TRUE` when interested in the grade dimension) to
compute disproportionality rates and risk ratios.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level police-notification detail (latest year)
pnd <- fetch_police_notifications_detail(2025)

# District/state-level detail, filtered to the subgroup marginals
library(dplyr)
fetch_police_notifications_detail(2024, level = "district") %>%
  filter(is_district, grade_level == "TOTAL") %>%
  select(district_name, subgroup, police_count, violent_count, hibcount)

# Disproportionality by subgroup AND grade
fetch_police_notifications_detail(2025, level = "district") %>%
  filter(is_state) %>%
  calc_discipline_rates_by_subgroup(by_grade = TRUE)
} # }
```
