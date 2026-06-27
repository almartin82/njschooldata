# Fetch Restraint & Seclusion Incidents (school-level)

Downloads the NJ DOE standalone DARS (Discipline & Restraint)
school-level Restraint & Seclusion workbook. Each row reports, for one
school and one student group, counts (and percents) of restraint and
seclusion events across ten categories. Restraint and seclusion are
among the highest-liability, most legally sensitive metrics in a
building and are concentrated in special-education settings; this
fetcher surfaces them in a cross-district comparable form.

## Usage

``` r
fetch_restraint_seclusion(end_year, level = "school")
```

## Arguments

- end_year:

  A school year: 2023 (SY2022-23) or 2024 (SY2023-24).

- level:

  Only `"school"` is supported (the DARS workbook is school-level only).
  Other values error.

## Value

Data frame with `end_year`, the entity identifiers
(`county_id`/`county_name`/`district_id`/`district_name`/
`school_id`/`school_name`), the raw `student_group` plus normalized
`subgroup` and `grade_level`, the 20 numeric count/percent columns, and
the standard aggregation flags (`is_state`, `is_county`, `is_district`,
`is_school`, `is_charter`, `is_charter_sector`, `is_allpublic`).

## Details

**Source.** Standalone Excel workbooks under the NJ DOE annual-report
portal (`nj.gov/education/vandv/annualreport/dars/`) - a source distinct
from the violence/vandalism/HIB SPR data exposed by
[`fetch_violence_vandalism_hib`](https://almartin82.github.io/njschooldata/reference/fetch_violence_vandalism_hib.md).
Covered years: **end_year 2023 (SY2022-23) and 2024 (SY2023-24)** only;
other years error. The data sheet is the second sheet
(`Restraints and Seclusions`); its real header is row 12.

**School-level only, no aggregates.** The workbook contains one row per
school per student group and has **no** state, district, or county
aggregate rows - so `is_school` is `TRUE` on every row and
`is_state`/`is_county`/`is_district` are `FALSE`. The `level` argument
therefore accepts only `"school"`.

**SSDS three-category background.** NJ's Student Safety Data System
groups events into restraint (physical and/or mechanical), seclusion,
and occasions where both occurred together; the 20 value columns expand
those categories (e.g. `restraint_physical_count`, `seclusion_count`,
`both_restraint_seclusion_count`) with a count and a percent each.

**Suppression -\> NA (never a guessed number).** Small cells are masked:
`"*"` hides a value entirely, and `"<5"` is a published RANGE standing
in for 1-4 students. Both become `NA`; the coercion never extracts the
literal `5` from `"<5"`. A real published `0` stays `0`.

**Student group.** The raw `Student Group` label (`"Schoolwide"` in
2022-23, `"School Total"` in 2023-24, plus race, gender, economically
disadvantaged, students with disabilities, and grade labels) is
preserved as `student_group` and additionally split into normalized
`subgroup` + `grade_level`. Grade rows get
`subgroup = "total population"` and a grade label (`"PK"`, `"K"`,
`"01"-"12"`); the rest get `grade_level = "TOTAL"`.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level restraint & seclusion (latest year)
rs <- fetch_restraint_seclusion(2024)

# Schoolwide totals: schools with the most restraint occasions
library(dplyr)
fetch_restraint_seclusion(2024) %>%
  filter(subgroup == "total population", grade_level == "TOTAL") %>%
  slice_max(restraint_count, n = 10) %>%
  select(district_name, school_name, restraint_count, seclusion_count)

# Students-with-disabilities share of restraint events, Newark (district 3570)
fetch_restraint_seclusion(2023) %>%
  filter(district_id == "3570",
         subgroup %in% c("total population", "students with disabilities"),
         grade_level == "TOTAL") %>%
  select(school_name, subgroup, restraint_count)
} # }
```
