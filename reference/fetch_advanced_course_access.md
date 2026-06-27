# Fetch Advanced-Coursework Access & Equity Data

A single front door over three NJ DOE School Performance Report (SPR)
sheet families describing access to and equity of advanced coursework.
Unlike
[`fetch_ap_participation`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md)
(overall AP/IB participation), these surface whether a school *offers*
advanced courses, AP/IB/dual-enrollment participation broken out *by
student group*, and Structured Learning Experience (SLE) participation.

## Usage

``` r
fetch_advanced_course_access(
  end_year,
  type = c("courses_offered", "participation_by_group", "sle"),
  level = "school"
)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - e.g. the 2023-24
  school year is `end_year` 2024. Coverage depends on `type`:
  `"courses_offered"` and `"sle"` cover 2017-2025;
  `"participation_by_group"` covers 2021-2025 (earlier years error).

- type:

  One of `"courses_offered"`, `"participation_by_group"`, or `"sle"`.

- level:

  One of `"school"` or `"district"`. `"district"` returns district and
  state-level rows (the statewide `is_state` row lives in the District
  workbook).

## Value

Data frame with entity identifiers, `school_year` (when the sheet
carries it), the type-specific data columns described above, `subgroup`
(for `"participation_by_group"`), and the standard aggregation flags
(`is_state`, `is_county`, `is_district`, `is_school`, `is_charter`,
`is_charter_sector`, `is_allpublic`).

## Details

The `type` argument selects one of three sheet families, each with its
own coverage window and schema drift across the 2024-25 SPR redesign:

- `"courses_offered"` – one row per school per advanced course
  (`course_name`, `students_enrolled`, `students_tested`). Sheet
  `APIBCoursesOffered` for **end_year 2017-2024**, renamed
  `ABIBCoursesOffered` for 2025 (the A-B-IB typo is the real 2025 sheet
  name). The 2025 sheet adds a single-value `school_year` column.

- `"participation_by_group"` – one row per entity per student group
  (`subgroup`), with the percent of students enrolled in one or more
  AP/IB courses (`apib_pct_school`) and one or more dual-enrollment
  courses (`dual_pct_school`), plus the statewide rate for the same
  group (`apib_pct_state`, `dual_pct_state`). Sheet
  `APIBDualEnrPartByStudentGrp` for **end_year 2021-2024** (**absent
  2017-2020**; earlier years error), renamed
  `AP_IB_Dual_PartStudentGroup` for 2025. The 2025 sheet is a multi-year
  trend table (`school_year` 2020-21..2024-25) filtered to the requested
  academic year, and additionally carries district-level rates
  (`apib_pct_district`, `dual_pct_district`), which exist only for 2025.

- `"sle"` – one row per school with the percent of students in a
  Structured Learning Experience. The entity's own rate is
  `sle_pct_school` (School workbook) or `sle_pct_district` (District
  workbook), alongside the statewide rate `sle_pct_state`; the 2025
  School workbook carries both `sle_pct_school` and its district's
  `sle_pct_district`. Sheet `CTE_SLEParticipation` for **end_year
  2017-2023** (only the SLE columns are surfaced; CTE participation and
  industry-valued credentials live in
  [`fetch_cte_participation`](https://almartin82.github.io/njschooldata/reference/fetch_cte_participation.md)
  /
  [`fetch_industry_credentials`](https://almartin82.github.io/njschooldata/reference/fetch_industry_credentials.md)),
  renamed `SLE_Participation` for 2024-2025. The published column names
  drift across both year and level (e.g.
  `sleperc`/`sleschool`/`sledistrict`/`sle_school`) and are harmonized
  onto the stable schema above.

Every rate/count is coerced with
[`spr_value_numeric()`](https://almartin82.github.io/njschooldata/reference/spr_value_numeric.md),
which strips `"%"` and thousands commas and maps suppression / no-data
strings (e.g. `"There is no data available for this school year."`,
`"Enrollment for this group was less than 10 students."`) to `NA` –
never to a guessed number. A genuine published `0` is preserved as `0`.
All values come from the NJ DOE SPR workbooks.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Which advanced courses does each school offer, and how many enroll?
courses <- fetch_advanced_course_access(2024, type = "courses_offered")
courses %>%
  filter(district_id == "3570") %>%
  slice_max(students_enrolled, n = 10) %>%
  select(school_name, course_name, students_enrolled, students_tested)

# AP/IB access gap by student group, statewide (district workbook)
fetch_advanced_course_access(2024, type = "participation_by_group",
                             level = "district") %>%
  filter(is_state) %>%
  select(subgroup, apib_pct_state, dual_pct_state)

# Structured Learning Experience participation, latest year
fetch_advanced_course_access(2025, type = "sle") %>%
  filter(is_school) %>%
  slice_max(sle_pct_school, n = 10) %>%
  select(district_name, school_name, sle_pct_school, sle_pct_state)
} # }
```
